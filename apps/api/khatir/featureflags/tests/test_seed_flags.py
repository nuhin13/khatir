"""Verify the 7 flags seeded by 0002_seed_flags (T-004).

The seed is a no-op when auto-run under the test settings module (so it does not
pollute the EPIC-13.T-002/T-003 endpoint tests that assert an empty table), so
these tests invoke ``seed_flags`` directly to exercise it.

Kill-switch convention: ``enabled=True`` = feature IS ON; flipping to ``False``
kills the feature. All 5 kill-switches + 2 default flags seed enabled=True.
"""

from __future__ import annotations

from importlib import import_module

import pytest
from django.apps import apps as django_apps

from khatir.featureflags.models import FeatureFlag

pytestmark = pytest.mark.django_db

KILL_SWITCH_KEYS = {
    "warnings_feature",
    "reviews_feature",
    "history_flags_feature",
    "free_text_feature",
    "master_kill_switch",
}
FEATURE_FLAG_KEYS = {"voice_tenant_entry", "dmp_enabled"}
ALL_KEYS = KILL_SWITCH_KEYS | FEATURE_FLAG_KEYS

_MODULE = import_module("khatir.featureflags.migrations.0002_seed_flags")


@pytest.fixture
def seeded() -> None:
    """Run the seed directly (schema_editor=None bypasses the test-mode skip)."""
    _MODULE.seed_flags(django_apps, None)


def test_flags_seeded(seeded: None) -> None:
    assert ALL_KEYS <= set(FeatureFlag.objects.values_list("key", flat=True))
    assert FeatureFlag.objects.filter(key__in=ALL_KEYS).count() == 7


def test_kill_switches_enabled_by_default(seeded: None) -> None:
    """enabled=True = feature is ON; admin flips to False to kill it."""
    for key in KILL_SWITCH_KEYS:
        flag = FeatureFlag.objects.get(key=key)
        assert flag.enabled is True, key
        assert flag.scope == "global", key


def test_default_feature_flags_enabled(seeded: None) -> None:
    for key in FEATURE_FLAG_KEYS:
        flag = FeatureFlag.objects.get(key=key)
        assert flag.enabled is True, key
        assert flag.scope == "global", key


def test_voice_tenant_entry_present(seeded: None) -> None:
    """EPIC-04 depends on this flag existing."""
    assert FeatureFlag.objects.get(key="voice_tenant_entry").enabled is True


def test_seed_is_idempotent(seeded: None) -> None:
    """Re-running the seed must not duplicate rows (update_or_create)."""
    _MODULE.seed_flags(django_apps, None)
    assert FeatureFlag.objects.filter(key__in=ALL_KEYS).count() == 7


def test_seed_reversible(seeded: None) -> None:
    """Reverse removes exactly the 7 seeded keys."""
    _MODULE.unseed_flags(django_apps, None)
    assert FeatureFlag.objects.filter(key__in=ALL_KEYS).count() == 0


def test_auto_run_skipped_in_test_db() -> None:
    """Without the explicit seed fixture, the test DB has none of these keys."""
    assert FeatureFlag.objects.filter(key__in=ALL_KEYS).count() == 0
