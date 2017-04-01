from django.conf.urls import url, include
from django.contrib import admin

from .views import HomeView

urlpatterns = [
  url(
    regex=r"^$",
    view=HomeView.as_view(),
    name="site-home"
  ),
]
