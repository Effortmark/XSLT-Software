import os
import time
import re
from flask import render_template, flash, request, redirect, url_for, Blueprint
import urllib.request
from werkzeug.utils import secure_filename

bp = Blueprint('formBlueprint', __name__, url_prefix="")

# Variables set for the upload file function
UPLOAD_FOLDER = "/tmp/"
ALLOWED_EXTENSIONS = "pptx",

# upload form function
def allowed_file(filename):
    return '.' in filename and \
            filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

'''
This is the file upload method. It is set to work on the index page, or /.
You can add onto this by including additional routes if you want other pages to host the upload form.
'''
@bp.route('/', methods=['GET', 'POST'])
def upload_file():
    if request.method == 'POST':
        # Check if the post request has a file part
        if 'file' not in request.files:
            flash('No file part')
            return redirect(request.url)
        file = request.files['file']
        # if there's no file selected, or submitted with an empty part without a filename
        if file.filename == '':
            flash('No file selected')
            return redirect(request.url)
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            file.save(os.path.join(UPLOAD_FOLDER, filename))

    # Wait until it can see the file exists in the temp folder before returning the results.
    while not os.path.exists(UPLOAD_FOLDER + filename):
        time.sleep(2)

    return redirect(url_for('translatorBlueprint.results', filename=filename))
