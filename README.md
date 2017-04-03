# VoGo

Voting on the go. A django-elm application that allows users to create a vote system within a certain range of where the question was made. 

Based off of the Django-Elm interface built [here](https://github.com/dmattia/django-elm). The system allows for users to create an elm frontend for a project and serve and compile that frontend using Django's fileserver and templating. 

### Running
Project is run with django, use is similar to basic startup for any django project.
```
python manage.py makemigrations main
python manage.py migrate
python manage.py runserver
```
Project is then live at `localhost:8000` and votes can be add with a location

### Technologies
Django 1.10.6

Elm 0.18

### Installation

- pip install django
- elm-package install

### Todo

- [ ] Make it possible for users to set an expiration date
- [ ] Give users a way to change the defualt distance of the vote submitted 
