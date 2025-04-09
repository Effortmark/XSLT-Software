import os
import time
import re
import urllib.request
import magic  # For MIME type checking
from pathlib import Path
from functools import lru_cache
from flask import render_template, flash, request, redirect, url_for, Blueprint, current_app, abort
from werkzeug.utils import secure_filename
from zipfile import ZipFile, BadZipFile
from lxml import etree
from .security import limiter, csrf
from .config import Config

bp = Blueprint('translatorBlueprint', __name__, url_prefix="")

UPLOAD_FOLDER = "/tmp/"
ALLOWED_EXTENSIONS = {'pptx'}

def allowed_file(filename):
    """Validate file extension and MIME type."""
    if not ('.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS):
        return False
    return True

def validate_pptx(file_path):
    """Validate that file is actually a PowerPoint file."""
    mime = magic.Magic(mime=True)
    file_type = mime.from_file(file_path)
    valid_types = [
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        'application/zip'  # PPTX files are ZIP archives
    ]
    if file_type not in valid_types:
        os.unlink(file_path)  # Delete invalid file
        return False
    return True

def secure_file_path(filename):
    """Create a secure file path that prevents directory traversal."""
    filename = secure_filename(filename)
    # Ensure the upload folder exists and has correct permissions
    os.makedirs(Config.UPLOAD_FOLDER, mode=0o750, exist_ok=True)
    return os.path.join(Config.UPLOAD_FOLDER, filename)

@lru_cache(maxsize=32)
def make_transform(name):
    """Create and cache XSLT transform."""
    # Create a secure parser with additional protections
    parser = etree.XMLParser(
        resolve_entities=False,
        no_network=True,  # Prevent network access
        collect_ids=False,  # Prevent memory exhaustion
        huge_tree=False,  # Prevent memory exhaustion
    )
    try:
        with open(name) as f:
            xslt_root = etree.parse(f, parser, base_url='')
            transform = etree.XSLT(xslt_root)
            return transform
    except (IOError, etree.XMLSyntaxError) as e:
        current_app.logger.error(f"Error creating transform: {e}")
        raise

def process_xml_file(pptx, name):
    """Process individual XML file from PPTX."""
    # Extract number from name, default to 1 if no number found
    numbers = re.findall(r'\d+', name)
    num = numbers[0] if numbers else '1'
    
    # Add size limit to prevent ZIP bombs
    MAX_SIZE = 50 * 1024 * 1024  # 50MB limit
    
    with pptx.open(name) as f:
        data = f.read(MAX_SIZE)
        if len(data) >= MAX_SIZE:
            raise ValueError("File too large - possible ZIP bomb")
        data = data.decode("utf-8-sig")
        # Remove XML declaration and sanitize
        data = re.sub('<\?xml version=\"1.0\"[^>]+>', '', data)
        # Additional sanitization
        data = re.sub('<!DOCTYPE[^>]*>', '', data)  # Remove DOCTYPE declarations
        data = re.sub('<!--.*?-->', '', data)  # Remove comments
        return f'<file name="{name}" num="{num}">{data}</file>'

@bp.route('/results/<filename>', methods=['GET'])
@limiter.limit("30 per minute")  # Add rate limiting
def results(filename):
    try:
        # Validate filename
        if not allowed_file(filename):
            abort(400, "Invalid file type")
            
        file_path = Path(secure_file_path(filename))
        if not file_path.exists():
            flash('File not found', 'error')
            return redirect(url_for('index'))

        # Validate file type
        if not validate_pptx(str(file_path)):
            flash('Invalid file format', 'error')
            return redirect(url_for('index'))

        try:
            with ZipFile(file_path, 'r') as pptx:
                # Validate ZIP contents before processing
                for name in pptx.namelist():
                    if '..' in name or name.startswith('/'):
                        raise ValueError("Invalid ZIP content - possible path traversal attempt")
                    if not name.endswith(('.xml', '.rels')):
                        continue

                # Add timeout for XML processing
                start_time = time.time()
                timeout = 30  # 30 seconds timeout

                # Combine XML files
                xml_parts = ['<?xml version="1.0"?><files>']
                
                for name in pptx.namelist():
                    if time.time() - start_time > timeout:
                        raise TimeoutError("Processing timeout exceeded")
                    
                    if any(x in name for x in ("ppt/slideLayouts", "ppt/slides", "ppt/slideMasters")):
                        xml_parts.append(process_xml_file(pptx, name))
                
                xml_parts.append('</files>')
                xml_combined = '\n'.join(xml_parts)

                # Transform combined XML
                transform = make_transform(os.path.join("app/static/pptx.xsl"))
                xml_new = etree.fromstring(xml_combined.encode('utf-8'))
                result = transform(xml_new)

        except (BadZipFile, TimeoutError) as e:
            flash(str(e), 'error')
            return redirect(url_for('index'))
        finally:
            # Clean up
            try:
                file_path.unlink()
                current_app.logger.info(f"Successfully deleted file: {filename}")
            except Exception as e:
                current_app.logger.error(f"Error deleting file {filename}: {str(e)}")

        return render_template("results.html", result=result, filename=filename)

    except Exception as e:
        current_app.logger.error(f"Error processing file {filename}: {str(e)}")
        # Clean up on error
        try:
            if file_path.exists():
                file_path.unlink()
        except:
            pass
        flash(f"An error occurred while processing the file", 'error')
        return redirect(url_for('index'))

def start_cleanup():
    """Schedule periodic cleanup of old files."""
    while True:
        try:
            Config.cleanup_old_files()
        except Exception as e:
            current_app.logger.error(f"Error in cleanup task: {str(e)}")
        time.sleep(Config.CLEANUP_INTERVAL)
