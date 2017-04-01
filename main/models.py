from __future__ import unicode_literals

from django.db import models
from uuid import uuid4

def generateUUID():
    return str(uuid4())

# Create your models here.
class Question(models.Model):
    id = models.CharField(primary_key=True, default=generateUUID, editable=False, max_length=40)
    title = models.CharField(max_length=20)
    prompt = models.TextField(max_length=500)
    expiration = models.DateTimeField('date published')
    lat = models.DecimalField(max_digits=9, decimal_places=6)
    lon = models.DecimalField(max_digits=9, decimal_places=6)
    radius = models.DecimalField(max_digits=50, decimal_places=5, default="")

    def __str__(self):
        return self.title

class Response(models.Model):
    id = models.CharField(primary_key=True, default=generateUUID, editable=False, max_length=40)
    question_id = models.ForeignKey(Question, on_delete=models.CASCADE)
    vote = models.BooleanField(default=False)
    ip_addr = models.GenericIPAddressField()

class MCQuestion(Question):
    propmt = models.TextField(max_length=500)
