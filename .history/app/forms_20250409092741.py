import os
import time
from flask import render_template, flash, request, redirect, url_for, Blueprint, current_app
from werkzeug.utils import secure_filename
from .config import Config

bp = Blueprint('formBlueprint', __name__, url_prefix="")

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in Config.ALLOWED_EXTENSIONS

@bp.route('/', methods=['GET', 'POST'])
def upload_file():
    if request.method == 'POST':
        # Check if the post request has a file part
        if 'file' not in request.files:
            flash('No file part', 'error')
            return redirect(request.url)
            
        file = request.files['file']
        
        # if there's no file selected
        if file.filename == '':
            flash('No file selected', 'error')
            return redirect(request.url)
            
        if not allowed_file(file.filename):
            flash('Invalid file type. Only PPTX files are allowed.', 'error')
            return redirect(request.url)
            
        if file:
            try:
                filename = secure_filename(file.filename)
                file_path = os.path.join(Config.UPLOAD_FOLDER, filename)
                file.save(file_path)
                
                # Wait for file to be saved (with timeout)
                max_wait = 5  # Maximum wait time in seconds
                start_time = time.time()
                while not os.path.exists(file_path):
                    if time.time() - start_time > max_wait:
                        flash('Error: File upload timed out', 'error')
                        return redirect(request.url)
                    time.sleep(0.1)
                
                return redirect(url_for('translatorBlueprint.results', filename=filename))
            except Exception as e:
                current_app.logger.error(f"Error uploading file: {str(e)}")
                flash('Error uploading file', 'error')
                return redirect(request.url)
    
    return render_template('index.html')
