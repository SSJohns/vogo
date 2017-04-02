from __future__ import unicode_literals

from django.db import models
from uuid import uuid4

def generateUUID():
    return str(uuid4())

# Create your models here.
class AbstractQuestion(models.Model):
    id = models.CharField(primary_key=True, default=generateUUID, editable=False, max_length=40)
    title = models.CharField(max_length=20)
    prompt = models.TextField(max_length=500, null=True)
    expiration = models.DateTimeField('expires')
    lat = models.DecimalField(max_digits=9, decimal_places=6)
    lon = models.DecimalField(max_digits=9, decimal_places=6)
    radius = models.DecimalField(max_digits=50, decimal_places=5, default="")
    score = models.IntegerField(default=0)

    def __str__(self):
        return self.title

    class Meta:
        abstract = True

class AbstractResponse(models.Model):
    id = models.CharField(primary_key=True, default=generateUUID, editable=False, max_length=40)
    ip_addr = models.GenericIPAddressField()

    class Meta:
        abstract = True

class BoolQuestion(AbstractQuestion):
    pass

class BoolResponse(AbstractResponse):
    vote_resp = models.BooleanField(default=False)
    question_id = models.ForeignKey(BoolQuestion, on_delete=models.CASCADE)

class MCQuestion(AbstractQuestion):
    @property
    def possibleAnswers(self):
        return MCOption.objects.filter(question_id=self)

class MCOption(models.Model):
    id = models.CharField(primary_key=True, default=generateUUID, editable=False, max_length=40)
    question_id = models.ForeignKey(MCQuestion, related_name='options', on_delete=models.CASCADE)
    option = models.TextField(max_length=50)

class MCResponse(AbstractResponse):
    vote_resp = models.IntegerField(default=1)
    question_id = models.ForeignKey(MCQuestion, on_delete=models.CASCADE)
