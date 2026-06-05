"""Verify the ``gov_export_enabled`` flag seeded by govexport 0002 (EPIC-26.T-005).

The seed is a no-op when auto-run under the test settings module (so it does not
pollute the EPIC-26.T-004 endpoint tests that assert default-OFF against an empty
flags table), so these tests invoke ``seed_gov_export_flag`` directly to exercise
it. The flag is DEFAULT OFF — seeded ``enabled=False``; admin flips it ON.
"""

from __future__ import annotations

from importlib import import_module

import pytest
from django.apps import apps as django_apps

from khatir.featureflags.models import FeatureFlag

pytestmark = pytest.mark.django_db

_KEY = "gov_export_enabled"
_MODULE = import_module("khatir.govexport.migrations.0002_seed_gov_export_flag")


@pytest.fixture
def seeded() -> None:
    """Run the seed directly (schema_editor=None bypasses the test-mode skip)."""
    _MODULE.seed_gov_export_flag(django_apps, None)


def test_flag_seeded_off_by_default(seeded: None) -> None:
    flag = FeatureFlag.objects.get(key=_KEY)
    assert flag.enabled is False
    assert flag.scope == "global"
    assert flag.description != ""


def test_seed_is_idempotent(seeded: None) -> None:
    _MODULE.seed_gov_export_flag(django_apps, None)
    assert FeatureFlag.objects.filter(key=_KEY).count() == 1


def test_seed_reversible(seeded: None) -> None:
    _MODULE.unseed_gov_export_flag(django_apps, None)
    assert FeatureFlag.objects.filter(key=_KEY).count() == 0


def test_auto_run_skipped_in_test_db() -> None:
    """Without the explicit seed fixture, the test DB has no gov_export_enabled row."""
    assert FeatureFlag.objects.filter(key=_KEY).count() == 0
