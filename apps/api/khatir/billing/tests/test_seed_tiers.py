"""Verify the 6 default ``PricingTier`` rows seeded by 0002_seed_tiers (T-002).

The data migration runs as part of the test-DB setup, so the rows are present
without re-invoking it. Keys mirror ``PricingTierKey`` in
``docs/architecture/enums.md``.
"""

from __future__ import annotations

from decimal import Decimal

import pytest

from khatir.billing.models import PricingTier

pytestmark = pytest.mark.django_db

EXPECTED_KEYS = {
    "free",
    "per_tenant",
    "bundle_20",
    "bundle_40",
    "unlimited_monthly",
    "unlimited_annual",
}


def test_6_tiers_seeded() -> None:
    seeded = set(PricingTier.objects.values_list("key", flat=True))
    assert EXPECTED_KEYS <= seeded
    assert PricingTier.objects.filter(key__in=EXPECTED_KEYS).count() == 6


def test_free_tier_correct() -> None:
    free = PricingTier.objects.get(key="free")
    assert free.tenant_min == 0
    assert free.tenant_max == 2
    assert free.monthly_price is None
    assert free.annual_price is None
    assert free.includes_verification is False
    assert free.included_credits == 0
    assert free.active is True


def test_bundles_include_verification() -> None:
    for key in ("bundle_20", "bundle_40", "unlimited_monthly", "unlimited_annual"):
        tier = PricingTier.objects.get(key=key)
        assert tier.includes_verification is True, key
        assert tier.included_credits > 0, key


def test_per_tenant_tier() -> None:
    per_tenant = PricingTier.objects.get(key="per_tenant")
    assert per_tenant.tenant_min == 3
    assert per_tenant.tenant_max is None
    assert per_tenant.monthly_price == Decimal("30.00")
    assert per_tenant.includes_verification is False


def test_unlimited_tiers_have_null_tenant_max() -> None:
    for key in ("per_tenant", "unlimited_monthly", "unlimited_annual"):
        assert PricingTier.objects.get(key=key).tenant_max is None, key


def test_tiers_sort_order_unique_and_ordered() -> None:
    orders = list(
        PricingTier.objects.filter(key__in=EXPECTED_KEYS)
        .order_by("sort_order")
        .values_list("key", "sort_order")
    )
    sort_values = [o for _, o in orders]
    assert sort_values == sorted(sort_values)
    assert len(set(sort_values)) == len(sort_values)


def test_seed_is_idempotent() -> None:
    """Re-running the seed must not duplicate rows (update_or_create)."""
    from importlib import import_module

    from django.apps import apps as django_apps

    # Module name starts with a digit, so import via ``getattr`` on the package.
    module = import_module("khatir.billing.migrations.0002_seed_tiers")
    module.seed_tiers(django_apps, None)
    assert PricingTier.objects.filter(key__in=EXPECTED_KEYS).count() == 6
