# This is where all the configuration goes to ensure it is outside the app and safe. Right now it just has a secret key which is needed to check the security of the file type being uploaded.
import os
import shutil
import time
from datetime import timedelta
from pathlib import Path

class Config:
    # Generate a secure random secret key if none is set
    SECRET_KEY = os.environ.get('SECRET_KEY') or os.urandom(24).hex()
    
    # Heroku-compatible upload folder
    UPLOAD_FOLDER = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'tmp')
    MAX_CONTENT_LENGTH = 50 * 1024 * 1024  # 50MB max-limit
    
    # Security settings
    SESSION_COOKIE_SECURE = True  # Only send cookies over HTTPS
    SESSION_COOKIE_HTTPONLY = True  # Prevent JavaScript access to session cookie
    SESSION_COOKIE_SAMESITE = 'Lax'  # Balanced security for cookies
    PERMANENT_SESSION_LIFETIME = timedelta(minutes=30)
    
    # CSRF protection
    WTF_CSRF_ENABLED = True
    WTF_CSRF_TIME_LIMIT = 3600  # 1 hour
    
    # Logging
    LOG_LEVEL = 'INFO'
    LOG_FORMAT = '%(asctime)s [%(levelname)s] %(message)s'
    
    # Heroku specific settings
    DYNO = os.environ.get('DYNO', '')  # Heroku dyno identifier
    PORT = int(os.environ.get('PORT', 5000))  # Heroku port
    WEB_CONCURRENCY = int(os.environ.get('WEB_CONCURRENCY', 1))  # Number of workers
    
    # File cleanup settings
    MAX_FILE_AGE = 3600  # 1 hour in seconds
    CLEANUP_INTERVAL = 300  # 5 minutes in seconds
    
    @classmethod
    def init_app(cls, app):
        # Ensure upload folder exists
        os.makedirs(cls.UPLOAD_FOLDER, exist_ok=True)
        
        # Configure logging
        if not app.debug:
            import logging
            from logging.handlers import RotatingFileHandler
            
            file_handler = RotatingFileHandler(
                'tmp/app.log',
                maxBytes=10240,
                backupCount=10
            )
            file_handler.setFormatter(logging.Formatter(
                '%(asctime)s %(levelname)s: %(message)s '
                '[in %(pathname)s:%(lineno)d]'
            ))
            file_handler.setLevel(logging.INFO)
            app.logger.addHandler(file_handler)
            
            app.logger.setLevel(logging.INFO)
            app.logger.info('Application startup')
    
    @classmethod
    def cleanup_old_files(cls):
        """Remove files older than MAX_FILE_AGE from the upload folder."""
        try:
            current_time = time.time()
            for filename in os.listdir(cls.UPLOAD_FOLDER):
                file_path = os.path.join(cls.UPLOAD_FOLDER, filename)
                if os.path.isfile(file_path):
                    file_age = current_time - os.path.getmtime(file_path)
                    if file_age > cls.MAX_FILE_AGE:
                        try:
                            os.unlink(file_path)
                        except Exception as e:
                            print(f"Error deleting file {file_path}: {e}")
        except Exception as e:
            print(f"Error during cleanup: {e}")
