import os
from dotenv import load_dotenv
from datetime import timedelta

# Load environment variables from .env file
load_dotenv()

class Config:
    # Flask settings
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-key-please-change-in-production'
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB max file size
    
    # Upload settings
    UPLOAD_FOLDER = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'uploads')
    ALLOWED_EXTENSIONS = {'pptx'}
    
    # Security settings
    SESSION_COOKIE_SECURE = True
    SESSION_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = 'Lax'
    
    # Rate limiting
    RATELIMIT_DEFAULT = "200 per day"
    RATELIMIT_STORAGE_URL = "memory://"
    
    # Cleanup settings
    CLEANUP_INTERVAL = 3600  # Clean up every hour
    MAX_FILE_AGE = timedelta(hours=1)  # Files older than 1 hour will be deleted
    
    # Ensure upload directory exists
    @staticmethod
    def init_app(app):
        if not os.path.exists(Config.UPLOAD_FOLDER):
            os.makedirs(Config.UPLOAD_FOLDER)

    @classmethod
    def cleanup_old_files(cls):
        """Delete old files from the upload directory."""
        import time
        from pathlib import Path
        
        now = time.time()
        upload_dir = Path(cls.UPLOAD_FOLDER)
        
        if not upload_dir.exists():
            return
            
        for file_path in upload_dir.glob('*'):
            if file_path.name == '.gitkeep':
                continue
            
            if file_path.is_file():
                file_age = now - file_path.stat().st_mtime
                if file_age > cls.MAX_FILE_AGE.total_seconds():
                    try:
                        file_path.unlink()
                    except Exception as e:
                        # Log error but continue with other files
                        print(f"Error deleting {file_path}: {e}") 