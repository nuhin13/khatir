"""Tests for the Celery wiring.

Tests run in eager mode (``CELERY_TASK_ALWAYS_EAGER=True`` in test settings),
so tasks execute synchronously in-process — no live Redis broker required.
"""

from django.conf import settings

from config.celery import app as celery_app
from khatir.core.tasks import ping


def test_eager_mode_enabled_in_tests() -> None:
    assert settings.CELERY_TASK_ALWAYS_EAGER is True


def test_celery_app_configured() -> None:
    assert celery_app.main == "khatir"
    assert celery_app.conf.broker_url == settings.CELERY_BROKER_URL
    assert celery_app.conf.result_backend == settings.CELERY_RESULT_BACKEND


def test_ping_task_returns_pong() -> None:
    result = ping.delay()
    assert result.get() == "pong"


def test_ping_called_directly() -> None:
    assert ping() == "pong"


def test_ping_task_autodiscovered() -> None:
    assert "khatir.core.tasks.ping" in celery_app.tasks
