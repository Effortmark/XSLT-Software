import os
import time
import re
import urllib.request
from pathlib import Path
from functools import lru_cache
from flask import render_template, flash, request, redirect, url_for, Blueprint, current_app
from werkzeug.utils import secure_filename
from zipfile import ZipFile
from lxml import etree

bp = Blueprint('translatorBlueprint', __name__, url_prefix="")

UPLOAD_FOLDER = "/tmp/"
ALLOWED_EXTENSIONS = {'pptx'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@lru_cache(maxsize=32)
def make_transform(name):
    """Create and cache XSLT transform."""
    parser = etree.XMLParser(resolve_entities=False)
    try:
        with open(name) as f:
            xslt_root = etree.parse(f, parser, base_url='')
            return etree.XSLT(xslt_root)
    except (IOError, etree.XMLSyntaxError) as e:
        current_app.logger.error(f"Error creating transform: {e}")
        raise

def process_xml_file(pptx, name):
    """Process individual XML file from PPTX."""
    # Extract number from name, default to 1 if no number found
    numbers = re.findall(r'\d+', name)
    num = numbers[0] if numbers else '1'
    
    with pptx.open(name) as f:
        data = f.read().decode("utf-8-sig")
        # Remove XML declaration
        data = re.sub('<\?xml version=\"1.0\"[^>]+>', '', data)
        return f'<file name="{name}" num="{num}">{data}</file>'

@bp.route('/results/<filename>', methods=['GET'])
def results(filename):
    try:
        file_path = Path(UPLOAD_FOLDER) / secure_filename(filename)
        if not file_path.exists():
            flash('File not found', 'error')
            return redirect(url_for('index'))

        with ZipFile(file_path, 'r') as pptx:
            # Combine XML files
            xml_parts = ['<?xml version="1.0"?><files>']
            
            for name in pptx.namelist():
                if any(x in name for x in ("ppt/slideLayouts", "ppt/slides", "ppt/slideMasters")):
                    xml_parts.append(process_xml_file(pptx, name))
            
            xml_parts.append('</files>')
            xml_combined = '\n'.join(xml_parts)

            # Transform combined XML
            transform = make_transform(os.path.join("app/static/pptx.xsl"))
            xml_new = etree.fromstring(xml_combined.encode('utf-8'))
            result = transform(xml_new)

        # Clean up
        file_path.unlink()
        return render_template("results.html", result=result, filename=filename)

    except Exception as e:
        current_app.logger.error(f"Error processing file {filename}: {str(e)}")
        flash(f"An error occurred while processing the file: {str(e)}", 'error')
        return redirect(url_for('index'))
