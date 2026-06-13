"""Celery application instance for the Khatir API.

The app reads its configuration from Django settings using the ``CELERY_``
namespace (broker URL, result backend, eager mode, etc. — all sourced from the
environment in ``config/settings/base.py``). Tasks are autodiscovered across
the ``khatir.*`` app packages (e.g. ``khatir/core/tasks.py``).
"""

import os

from celery import Celery

# Mirror config/wsgi.py: derive the settings module from DJANGO_ENV, defaulting
# to dev so `celery -A config worker` works out of the box in local dev.
_env = os.environ.get("DJANGO_ENV", "dev")
os.environ.setdefault("DJANGO_SETTINGS_MODULE", f"config.settings.{_env}")

app = Celery("khatir")

# All Celery settings live under the CELERY_ prefix in Django settings.
app.config_from_object("django.conf:settings", namespace="CELERY")

# Discover tasks.py modules in every installed app (khatir.core, ...).
app.autodiscover_tasks()
