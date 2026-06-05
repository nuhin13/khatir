"""Verify the ``tenant_app_enabled`` flag seeded by 0003 (EPIC-19.T-013).

The seed is a no-op when auto-run under the test settings module (so it does not
pollute the EPIC-13 endpoint tests that assert an empty table), so these tests
invoke ``seed_tenant_app_flag`` directly to exercise it.

Convention: ``enabled=True`` = feature IS ON; an admin flips it to ``False`` to
disable the tenant app. The flag seeds enabled=True (default on).
"""

from __future__ import annotations

from importlib import import_module

import pytest
from django.apps import apps as django_apps

from khatir.featureflags.models import FeatureFlag

pytestmark = pytest.mark.django_db

FLAG_KEY = "tenant_app_enabled"

_MODULE = import_module("khatir.featureflags.migrations.0003_seed_tenant_app_flag")


@pytest.fixture
def seeded() -> None:
    """Run the seed directly (schema_editor=None bypasses the test-mode skip)."""
    _MODULE.seed_tenant_app_flag(django_apps, None)


def test_tenant_app_flag_seeded(seeded: None) -> None:
    flag = FeatureFlag.objects.get(key=FLAG_KEY)
    assert flag.enabled is True
    assert flag.scope == "global"


def test_seed_is_idempotent(seeded: None) -> None:
    """Re-running the seed must not duplicate rows (update_or_create)."""
    _MODULE.seed_tenant_app_flag(django_apps, None)
    assert FeatureFlag.objects.filter(key=FLAG_KEY).count() == 1


def test_seed_reversible(seeded: None) -> None:
    """Reverse removes exactly the seeded key."""
    _MODULE.unseed_tenant_app_flag(django_apps, None)
    assert FeatureFlag.objects.filter(key=FLAG_KEY).count() == 0


def test_auto_run_skipped_in_test_db() -> None:
    """Without the explicit seed fixture, the test DB has no tenant_app flag."""
    assert FeatureFlag.objects.filter(key=FLAG_KEY).count() == 0
