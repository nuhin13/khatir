"""Verify the gatekeeper flag + visitor-log retention config seeded by 0002 (T-012).

The *flag* seed is a no-op when auto-run under the test settings module (so it
cannot pollute the EPIC-13 featureflags endpoint tests), so these tests invoke
``seed_gatekeeper_flag`` directly to exercise it. The *config* seed always runs,
so ``visitor_log_retention_days`` is asserted straight from the migrated DB.
"""

from __future__ import annotations

from importlib import import_module

import pytest
from django.apps import apps as django_apps

from khatir.core.config import get_config
from khatir.core.models import SystemConfig
from khatir.featureflags.models import FeatureFlag

pytestmark = pytest.mark.django_db

_MODULE = import_module("khatir.gatekeeper.migrations.0002_seed_gatekeeper_config")

FLAG_KEY = "gatekeeper_enabled"
CONFIG_KEY = "visitor_log_retention_days"


@pytest.fixture
def seeded_flag() -> None:
    """Run the flag seed directly (schema_editor=None bypasses the test-mode skip)."""
    _MODULE.seed_gatekeeper_flag(django_apps, None)


def test_gatekeeper_flag_seeded_enabled(seeded_flag: None) -> None:
    flag = FeatureFlag.objects.get(key=FLAG_KEY)
    assert flag.enabled is True
    assert flag.scope == "global"
    assert flag.description != ""


def test_flag_auto_run_skipped_in_test_db() -> None:
    """Without the explicit seed fixture, the test DB has no gatekeeper flag."""
    assert FeatureFlag.objects.filter(key=FLAG_KEY).count() == 0


def test_flag_seed_idempotent(seeded_flag: None) -> None:
    _MODULE.seed_gatekeeper_flag(django_apps, None)
    assert FeatureFlag.objects.filter(key=FLAG_KEY).count() == 1


def test_flag_seed_reversible(seeded_flag: None) -> None:
    _MODULE.unseed_gatekeeper_flag(django_apps, None)
    assert FeatureFlag.objects.filter(key=FLAG_KEY).count() == 0


def test_retention_config_seeded() -> None:
    """The config seed runs during the test DB build (core convention)."""
    row = SystemConfig.objects.get(key=CONFIG_KEY)
    assert row.type == "int"
    assert row.value == "90"
    assert row.description != ""


def test_retention_config_typed_via_get_config() -> None:
    coerced = get_config(CONFIG_KEY)
    assert isinstance(coerced, int)
    assert coerced == 90


def test_retention_config_seed_idempotent() -> None:
    _MODULE.seed_retention_config(django_apps, None)
    assert SystemConfig.objects.filter(key=CONFIG_KEY).count() == 1
