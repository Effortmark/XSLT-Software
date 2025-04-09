import os
from flask import Flask, render_template
from config import Config
from .pptxTranslator import start_cleanup
import threading

def create_app(test_config=None):
    app = Flask(__name__, instance_relative_config=True)
    
    if test_config is None:
        app.config.from_object(Config)
    else:
        app.config.update(test_config)

    # ensure the instance folder exists
    try:
        os.makedirs(app.instance_path)
    except OSError:
        pass

    @app.route('/')
    def index():
        return render_template("index.html")

    # Register blueprints
    from . import forms
    app.register_blueprint(forms.bp)

    # Initialize cleanup thread
    cleanup_thread = threading.Thread(target=start_cleanup)
    cleanup_thread.daemon = True
    cleanup_thread.start()

    from . import pptxTranslator
    app.register_blueprint(pptxTranslator.bp)

    return app

app = create_app()
