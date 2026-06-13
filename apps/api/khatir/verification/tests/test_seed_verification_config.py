"""Verify the EC verification config + ``nid_verification_enabled`` flag seed (T-005).

Two seeds back the NID/EC verification feature:

* ``core/0014_seed_verification_config`` seeds three Layer-3 ``SystemConfig`` rows
  (``ec_verification_provider``, ``ec_verification_endpoint``,
  ``ec_verification_dpa_reference``). This is *not* test-isolated, so the rows are
  present in the test DB and asserted directly.
* ``featureflags/0003_seed_nid_verification_flag`` seeds the
  ``nid_verification_enabled`` global flag enabled=True (default on). Like the
  baseline flag seed it is a no-op under test settings (so it never pollutes the
  EPIC-13 / EPIC-17 tests that assert the empty-table default-on fallback), so the
  seed function is invoked directly here.
"""

from __future__ import annotations

from importlib import import_module

import pytest
from django.apps import apps as django_apps

from khatir.core.models import SystemConfig
from khatir.featureflags.models import FeatureFlag
from khatir.verification.flags import (
    NID_VERIFICATION_ENABLED,
    is_feature_enabled,
)

pytestmark = pytest.mark.django_db

EC_CONFIG_KEYS = {
    "ec_verification_provider",
    "ec_verification_endpoint",
    "ec_verification_dpa_reference",
}

_FLAG_MODULE = import_module(
    "khatir.featureflags.migrations.0003_seed_nid_verification_flag"
)


@pytest.fixture
def flag_seeded() -> None:
    """Run the flag seed directly (schema_editor=None bypasses the test-mode skip)."""
    _FLAG_MODULE.seed_nid_verification_flag(django_apps, None)


def test_verification_config_seeded() -> None:
    """All three EC config keys exist as ``text`` rows with a description."""
    rows = {c.key: c for c in SystemConfig.objects.filter(key__in=EC_CONFIG_KEYS)}
    assert set(rows) == EC_CONFIG_KEYS
    for key, row in rows.items():
        assert row.type == "text", key
        assert row.description != "", key


def test_dpa_reference_seeded_empty() -> None:
    """DPA reference is present but empty — an admin must fill it before live use."""
    row = SystemConfig.objects.get(key="ec_verification_dpa_reference")
    assert row.value == ""
    assert "DPA" in row.description or "Data Processing" in row.description


def test_nid_verification_flag_seeded_on(flag_seeded: None) -> None:
    """The kill-switch flag is seeded global + enabled (default on)."""
    flag = FeatureFlag.objects.get(key=NID_VERIFICATION_ENABLED)
    assert flag.enabled is True
    assert flag.scope == "global"
    assert flag.description != ""


def test_flag_seed_idempotent(flag_seeded: None) -> None:
    """Re-running the flag seed never duplicates the row (update_or_create)."""
    _FLAG_MODULE.seed_nid_verification_flag(django_apps, None)
    assert (
        FeatureFlag.objects.filter(key=NID_VERIFICATION_ENABLED).count() == 1
    )


def test_flag_seed_reversible(flag_seeded: None) -> None:
    """Reverse removes exactly the seeded flag key."""
    _FLAG_MODULE.unseed_nid_verification_flag(django_apps, None)
    assert (
        FeatureFlag.objects.filter(key=NID_VERIFICATION_ENABLED).count() == 0
    )


def test_flag_auto_run_skipped_in_test_db() -> None:
    """Without the explicit seed fixture the test DB has no flag row, and the
    reader still resolves the feature *on* via its default-on fallback."""
    assert (
        FeatureFlag.objects.filter(key=NID_VERIFICATION_ENABLED).count() == 0
    )
    assert is_feature_enabled(NID_VERIFICATION_ENABLED, default=True) is True
