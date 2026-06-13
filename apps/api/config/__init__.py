"""Config package.

Importing the Celery app here ensures ``app`` is loaded when Django starts, so
the ``@shared_task`` decorator can find it. See ``config/celery.py``.
"""

from config.celery import app as celery_app

__all__ = ("celery_app",)
