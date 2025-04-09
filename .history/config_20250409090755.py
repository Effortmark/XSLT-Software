# This is where all the configuration goes to ensure it is outside the app and safe. Right now it just has a secret key which is needed to check the security of the file type being uploaded.
import os

class Config(object):
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'youratsayasaurus'
    # UPLOAD_FOLDER = UPLOAD_FOLDER
    # MAX_CONTENT_LENGTH = 16 * 1024 * 1024
