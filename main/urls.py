from django.conf.urls import url, include
from django.contrib import admin

from .views import HomeView, CreateView

urlpatterns = [
  url(
    regex=r"^$",
    view=HomeView.as_view(),
    name="site-home"
  ),
  url(
    regex=r"^create$",
    view=CreateView.as_view(),
    name="create"
  )
]
