"""WSGI entrypoint for the Khatir API."""

import os

from django.core.wsgi import get_wsgi_application

_env = os.environ.get("DJANGO_ENV", "dev")
os.environ.setdefault("DJANGO_SETTINGS_MODULE", f"config.settings.{_env}")

application = get_wsgi_application()
