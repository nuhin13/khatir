"""Tests for the ``PricingTier`` and ``Subscription`` models (T-001 §12)."""

from __future__ import annotations

from decimal import Decimal

import pytest
from django.db import models

from khatir.billing.enums import BillingCycle, SubscriptionStatus
from khatir.billing.models import PricingTier, Subscription

from .factories import PricingTierFactory, SubscriptionFactory

pytestmark = pytest.mark.django_db


# --- PricingTier ------------------------------------------------------------


def test_tier_create() -> None:
    tier: PricingTier = PricingTierFactory(  # type: ignore[assignment]
        key="free",
        label="Free",
        label_bn="বিনামূল্যে",
        tenant_min=0,
        tenant_max=2,
        monthly_price=None,
        annual_price=None,
        includes_verification=False,
        included_credits=0,
        active=True,
        sort_order=1,
    )
    assert tier.pk is not None
    assert tier.key == "free"
    assert tier.label == "Free"
    assert tier.label_bn == "বিনামূল্যে"
    assert tier.tenant_min == 0
    assert tier.tenant_max == 2
    assert tier.monthly_price is None
    assert tier.annual_price is None
    assert tier.includes_verification is False
    assert tier.included_credits == 0
    assert tier.active is True
    assert tier.sort_order == 1
    assert str(tier) == "Free (free)"


def test_tier_with_prices() -> None:
    tier: PricingTier = PricingTierFactory(  # type: ignore[assignment]
        key="bundle_20",
        label="Bundle 20",
        monthly_price=Decimal("499.00"),
        annual_price=Decimal("4999.00"),
        tenant_max=20,
        includes_verification=True,
        included_credits=20,
    )
    tier.refresh_from_db()
    assert tier.monthly_price == Decimal("499.00")
    assert tier.annual_price == Decimal("4999.00")
    assert tier.includes_verification is True
    assert tier.included_credits == 20


def test_tier_tenant_max_null_means_unlimited() -> None:
    tier: PricingTier = PricingTierFactory(key="unlimited_monthly", tenant_max=None)  # type: ignore[assignment]
    tier.refresh_from_db()
    assert tier.tenant_max is None


def test_tier_key_is_unique() -> None:
    field = PricingTier._meta.get_field("key")
    assert isinstance(field, models.CharField)
    assert field.unique is True


def test_tier_monthly_price_is_decimal() -> None:
    field = PricingTier._meta.get_field("monthly_price")
    assert isinstance(field, models.DecimalField)
    assert field.max_digits == 12
    assert field.decimal_places == 2
    assert field.null is True


def test_tier_annual_price_is_decimal() -> None:
    field = PricingTier._meta.get_field("annual_price")
    assert isinstance(field, models.DecimalField)
    assert field.max_digits == 12
    assert field.decimal_places == 2
    assert field.null is True


def test_tier_timestamps_present() -> None:
    tier: PricingTier = PricingTierFactory()  # type: ignore[assignment]
    assert tier.created_at is not None
    assert tier.updated_at is not None


# --- Subscription -----------------------------------------------------------


def test_subscription_create() -> None:
    sub: Subscription = SubscriptionFactory(  # type: ignore[assignment]
        billing_cycle=BillingCycle.MONTHLY,
        status=SubscriptionStatus.ACTIVE,
    )
    assert sub.pk is not None
    assert sub.user_id is not None
    assert sub.tier_id is not None
    assert sub.billing_cycle == BillingCycle.MONTHLY
    assert sub.status == SubscriptionStatus.ACTIVE
    assert sub.start_at is not None
    assert sub.next_billing_at is not None
    assert str(sub) == f"{sub.user} — {sub.tier} ({sub.billing_cycle})"


def test_subscription_annual_cycle() -> None:
    sub: Subscription = SubscriptionFactory(billing_cycle=BillingCycle.ANNUAL)  # type: ignore[assignment]
    sub.refresh_from_db()
    assert sub.billing_cycle == BillingCycle.ANNUAL


def test_subscription_status_past_due() -> None:
    sub: Subscription = SubscriptionFactory(status=SubscriptionStatus.PAST_DUE)  # type: ignore[assignment]
    sub.refresh_from_db()
    assert sub.status == SubscriptionStatus.PAST_DUE


def test_subscription_status_cancelled() -> None:
    sub: Subscription = SubscriptionFactory(status=SubscriptionStatus.CANCELLED)  # type: ignore[assignment]
    sub.refresh_from_db()
    assert sub.status == SubscriptionStatus.CANCELLED


def test_subscription_user_fk_protect() -> None:
    field = Subscription._meta.get_field("user")
    assert isinstance(field, models.ForeignKey)
    assert field.remote_field.on_delete is models.PROTECT


def test_subscription_tier_fk_protect() -> None:
    field = Subscription._meta.get_field("tier")
    assert isinstance(field, models.ForeignKey)
    assert field.remote_field.on_delete is models.PROTECT


def test_subscription_timestamps_present() -> None:
    sub: Subscription = SubscriptionFactory()  # type: ignore[assignment]
    assert sub.created_at is not None
    assert sub.updated_at is not None


# --- Enums match enums.md ---------------------------------------------------


def test_billing_cycle_values_match_spec() -> None:
    assert set(BillingCycle.values) == {"monthly", "annual"}


def test_subscription_status_values_match_spec() -> None:
    assert set(SubscriptionStatus.values) == {"active", "past_due", "cancelled"}


# --- Indexes ----------------------------------------------------------------


def test_subscription_index_on_user_status() -> None:
    index_fields = {tuple(idx.fields) for idx in Subscription._meta.indexes}
    assert ("user", "status") in index_fields
