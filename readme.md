# PPTX Accessibility Checker

A tool for checking your powerpoint presentations for accessibility issues.


# Table of contents

* [Introduction](#introduction)
* [Technologies](#technologies)
* [Setting up]{#setting-up}
* [Features]{#features}

# Introduction

This app is intended to support creating accessible presentations with Microsoft Powerpoint.
When a presentation is uploaded it returns an audit of the presentation that shows you what formatting is being used and whether your images have a description (also used as alt tag).

This project is open source, you have permission to fork and rework in your own way. If you do, please share back with the community.

## Technologies

This app uses:
- Python 3+
- Flask
- Virtualenv
- A number of Python and Flask modules (see requirements.txt)

As long as you have Python 3 installed, the rest takes care of itself and is packaged into `.flaskenv`.

# Setting up

## Python 3 and everything that comes with it.
All other requirements are installed once you create a virtual environment and run the app for the first time.

It's a Python app that uses Flask as a web framework to allow it to be run online.
The repository includes functionality for the service to run on Heroku as a hosted instance off the product branch.

## Setup virtual environment

The safest way to run this is by using a virtual python environment.

To install virtualenv for Python type:
`pip install virtualenv`

To create a new virtual environment for your project, go to the root directory in your terminal and type:
`virtualenv venv`

### Loading the virtual environment

To run the server go to the room directory in your terminal and type:
`source venv/bin/activate`

You will now see that the server is running. To stop it type:
`deactivate`

**HINT** Don't deactivate the server until you have stopped running Flask.

### Install requirements

All the required modules for the app are listed in `requirements.txt`.
With your virtual environment running, you should install the requirements from terminal and type:
`pip install -r requirements.txt`

## Flask

This a webapp using Flask to run Pyhton code on the web.
The dependancies for Flask will all be loaded the first time you run virtualenv.

To utilise the .flaskenv file that sets up basic app environment variables, like using the debug mode type:
`python -m flask run`

To start the Flask service without using the .flaskenv type:
`flask run`

To stop flask from terminal (on Mac) hold down `ctrl+c`

# Features

You can upload any powerpoint file created post 2007 with the extension `.pptx` and the app will return the slides in stripped down form and highlight your titles, text, lists and images so you can check the semantic order, and whether your images have included descriptions.

Now you can go back to your presentation and update the missing attributes and reorder them so that screen readers will be able to deliver the presentation as you intended.
