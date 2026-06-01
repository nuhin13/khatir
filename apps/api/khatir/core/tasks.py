"""Core Celery tasks.

Only plumbing/health tasks live here. Domain tasks (rent reminders, WhatsApp
sends, OCR, AI calls, nightly cleanup) belong to their own epics' apps.
"""

from celery import shared_task


@shared_task  # type: ignore[untyped-decorator]  # celery has no py.typed marker
def ping() -> str:
    """Debug heartbeat task. Returns ``"pong"`` to confirm the queue works."""
    return "pong"
