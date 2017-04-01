from django.contrib import admin

# Register your models here.
from .models import Question, Response, MCQuestion

admin.site.register(Question)
admin.site.register(MCQuestion)
admin.site.register(Response)
