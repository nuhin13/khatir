"""ASGI entrypoint for the Khatir API."""

import os

from django.core.asgi import get_asgi_application

_env = os.environ.get("DJANGO_ENV", "dev")
os.environ.setdefault("DJANGO_SETTINGS_MODULE", f"config.settings.{_env}")

application = get_asgi_application()
