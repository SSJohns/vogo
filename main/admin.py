from django.contrib import admin

# Register your models here.
from .models import BoolQuestion, BoolResponse, MCQuestion, MCOption, MCResponse

admin.site.register(BoolQuestion)
admin.site.register(MCQuestion)
admin.site.register(BoolResponse)
admin.site.register(MCOption)
admin.site.register(MCResponse)
