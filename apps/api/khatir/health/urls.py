"""URL routes mounted under ``/api/v1/``."""

from django.urls import path

from .views import config_public

urlpatterns = [
    path("config/public", config_public, name="config-public"),
]
