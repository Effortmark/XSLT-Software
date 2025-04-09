# This is where all the configuration goes to ensure it is outside the app and safe. Right now it just has a secret key which is needed to check the security of the file type being uploaded.
import os
from datetime import timedelta

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
    
    # Ensure upload folder exists
    @classmethod
    def init_app(cls, app):
        os.makedirs(cls.UPLOAD_FOLDER, exist_ok=True)
