#!/bin/bash

# Exit on error
set -e

echo "🚀 Starting deployment process..."

# Check if Heroku CLI is installed
if ! command -v heroku &> /dev/null; then
    echo "❌ Heroku CLI is not installed. Please install it first."
    exit 1
fi

# Check if logged in to Heroku
if ! heroku auth:whoami &> /dev/null; then
    echo "❌ Not logged in to Heroku. Please run 'heroku login' first."
    exit 1
fi

# Get app name from command line or use default
APP_NAME=${1:-"xslt-software"}

echo "📦 Creating Heroku app: $APP_NAME"

# Create app if it doesn't exist
if ! heroku apps:info $APP_NAME &> /dev/null; then
    heroku create $APP_NAME
fi

echo "🔑 Setting up environment variables..."

# Generate and set secret key
SECRET_KEY=$(python -c 'import os; print(os.urandom(24).hex())')
heroku config:set SECRET_KEY=$SECRET_KEY

# Set other environment variables
heroku config:set FLASK_ENV=production
heroku config:set FLASK_APP=app:app

echo "📦 Installing buildpacks..."

# Add required buildpacks
heroku buildpacks:clear
heroku buildpacks:add heroku/python
heroku buildpacks:add heroku/nodejs

echo "🚀 Deploying application..."

# Deploy the application
git push heroku version3:main

echo "🔄 Running database migrations..."

# Run any necessary setup
heroku run python manage.py init_db

echo "✅ Deployment complete!"
echo "🌐 Your application is now live at: https://$APP_NAME.herokuapp.com"

# Open the application in the browser
heroku open 