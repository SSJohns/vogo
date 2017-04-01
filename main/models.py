from __future__ import unicode_literals

from django.db import models
from location_field.models.spatial import LocationField


# Create your models here.
class Question(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=20)
    prompt = models.TextField(max_length=500)
    expiration = models.DateTimeField('date published')
    location = LocationField(based_fields=['city'], zoom=7, default=Point(1.0, 1.0))
    radius = models.DecimalField(max_digits=50, decimal_places=5, default="")

class Response(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    question_id = models.ForeignKey(Question, on_delete=models.CASCADE)
    vote = models.BooleanField(default=False)
    ip_addr = models.IPAddressField()

class MCQuestion(Question):
    propmt = models.TextField(max_length=500)

class MCOption(Response):
    optionText = models.CharField(max_length=200)
    question_id = models.ForeignKey(MCQuestion, on_delete=models.CASCADE)
    vote = models.IntegerField()
