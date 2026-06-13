"""Verify the ai_lease_enabled flag seeded by 0003_seed_ai_lease_flag (T-005).

The seed is a no-op when auto-run under the test settings module (so it does not
pollute the EPIC-13 flag-endpoint / leasedocs flag tests that assert an empty
table), so these tests invoke ``seed_flag`` directly to exercise it.
"""

from __future__ import annotations

from importlib import import_module

import pytest
from django.apps import apps as django_apps

from khatir.featureflags.models import FeatureFlag

pytestmark = pytest.mark.django_db

FLAG_KEY = "ai_lease_enabled"

_MODULE = import_module("khatir.featureflags.migrations.0003_seed_ai_lease_flag")


@pytest.fixture
def seeded() -> None:
    """Run the seed directly (schema_editor=None bypasses the test-mode skip)."""
    _MODULE.seed_flag(django_apps, None)


def test_flag_seeded_enabled(seeded: None) -> None:
    flag = FeatureFlag.objects.get(key=FLAG_KEY)
    assert flag.enabled is True
    assert flag.scope == "global"
    assert flag.description != ""


def test_seed_is_idempotent(seeded: None) -> None:
    _MODULE.seed_flag(django_apps, None)
    assert FeatureFlag.objects.filter(key=FLAG_KEY).count() == 1


def test_seed_reversible(seeded: None) -> None:
    _MODULE.unseed_flag(django_apps, None)
    assert FeatureFlag.objects.filter(key=FLAG_KEY).count() == 0


def test_auto_run_skipped_in_test_db() -> None:
    """Without the explicit seed fixture, the test DB has no such key."""
    assert FeatureFlag.objects.filter(key=FLAG_KEY).count() == 0
