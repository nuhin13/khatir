"""Verify the chatbot flag + config seeded by 0002_seed_chatbot_flag (T-005).

The seed is a no-op when auto-run under the test settings module (so it never
pollutes flag tests that assert an empty table), so these tests invoke
``seed_chatbot_flag`` directly to exercise it.

Convention: ``enabled=True`` = chatbot IS ON; admin flips to ``False`` to kill
it. The per-user rate-limit config rides in ``value_json``.
"""

from __future__ import annotations

from importlib import import_module

import pytest

from khatir.featureflags.models import FeatureFlag

pytestmark = pytest.mark.django_db

_MODULE = import_module("khatir.chatbot.migrations.0002_seed_chatbot_flag")


@pytest.fixture
def seeded() -> None:
    """Run the seed directly (schema_editor=None bypasses the test-mode skip)."""
    from django.apps import apps as django_apps

    _MODULE.seed_chatbot_flag(django_apps, None)


def test_chatbot_flag_seeded(seeded: None) -> None:
    flag = FeatureFlag.objects.get(key="chatbot_enabled")
    assert flag.enabled is True
    assert flag.scope == "global"


def test_chatbot_rate_limit_config_present(seeded: None) -> None:
    """The per-user hourly cap rides in value_json for ops tuning."""
    flag = FeatureFlag.objects.get(key="chatbot_enabled")
    assert flag.value_json == {"chatbot_rate_limit_per_hour": 60}


def test_seed_is_idempotent(seeded: None) -> None:
    """Re-running the seed must not duplicate the row (update_or_create)."""
    from django.apps import apps as django_apps

    _MODULE.seed_chatbot_flag(django_apps, None)
    assert FeatureFlag.objects.filter(key="chatbot_enabled").count() == 1


def test_seed_reversible(seeded: None) -> None:
    """Reverse removes exactly the chatbot_enabled key."""
    from django.apps import apps as django_apps

    _MODULE.unseed_chatbot_flag(django_apps, None)
    assert FeatureFlag.objects.filter(key="chatbot_enabled").count() == 0


def test_auto_run_skipped_in_test_db() -> None:
    """Without the explicit seed fixture, the test DB has no chatbot flag."""
    assert FeatureFlag.objects.filter(key="chatbot_enabled").count() == 0
