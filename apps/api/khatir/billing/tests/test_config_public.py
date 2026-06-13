"""Pricing tiers + subscription state in ``/config/public`` (EPIC-10 T-005 §12).

The six pricing tiers are seeded by ``billing.0002_seed_tiers``, so they are
present in every test DB; these tests exercise the public-config wiring against
that seeded catalogue rather than recreating it.

Covers:
* the active pricing tiers surface for anyone (auth optional), inactive ones do not;
* an authenticated caller gets a ``subscription`` block with their plan key,
  status, tenant usage, effective limit, and ``can_verify_nid``;
* an authenticated caller with no subscription falls back to the free tier
  (limit from the ``free_tier_tenant_limit`` config, ``can_verify_nid`` false);
* a cancelled subscription drops benefits back to the free tier;
* an unauthenticated caller gets the tiers but no ``subscription`` block;
* no sensitive billing data (prices / dates) leaks into the subscription block.
"""

from __future__ import annotations

import pytest
from rest_framework.test import APIClient

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.billing.enums import SubscriptionStatus
from khatir.billing.models import PricingTier
from khatir.billing.tests.factories import SubscriptionFactory
from khatir.core.config import invalidate_config
from khatir.core.models import SystemConfig

pytestmark = pytest.mark.django_db

CONFIG_PUBLIC = "/api/v1/config/public"


@pytest.fixture
def landlord() -> User:
    created: User = UserFactory(  # type: ignore[assignment]
        phone="+8801712345678", name="Landlord", role=Role.LANDLORD
    )
    return created


def _set_free_limit(value: int) -> None:
    SystemConfig.objects.update_or_create(
        key="free_tier_tenant_limit",
        defaults={"value": str(value), "type": "int", "description": "test"},
    )
    invalidate_config("free_tier_tenant_limit")


def test_config_public_tiers() -> None:
    response = APIClient().get(CONFIG_PUBLIC)
    assert response.status_code == 200

    tiers = response.json()["pricing"]["tiers"]
    keys = [t["key"] for t in tiers]
    # All six seeded tiers are active; returned in sort_order.
    assert keys == [
        "free",
        "per_tenant",
        "bundle_20",
        "bundle_40",
        "unlimited_monthly",
        "unlimited_annual",
    ]
    # Each serialized tier carries the public plan fields, nothing more.
    assert set(tiers[0]) == {
        "id",
        "key",
        "label",
        "label_bn",
        "tenant_min",
        "tenant_max",
        "monthly_price",
        "annual_price",
        "includes_verification",
        "included_credits",
    }


def test_config_public_inactive_tier_hidden() -> None:
    PricingTier.objects.filter(key="bundle_40").update(active=False)

    response = APIClient().get(CONFIG_PUBLIC)
    keys = [t["key"] for t in response.json()["pricing"]["tiers"]]
    assert "bundle_40" not in keys


def test_config_public_no_subscription_block_for_anon() -> None:
    response = APIClient().get(CONFIG_PUBLIC)
    assert response.status_code == 200
    assert "subscription" not in response.json()


def test_config_public_subscription_auth(landlord: User) -> None:
    _set_free_limit(2)
    tier = PricingTier.objects.get(key="bundle_20")  # tenant_max=20, verification
    SubscriptionFactory(user=landlord, tier=tier, status=SubscriptionStatus.ACTIVE)

    api = APIClient()
    api.force_authenticate(user=landlord)
    response = api.get(CONFIG_PUBLIC)
    assert response.status_code == 200

    block = response.json()["subscription"]
    assert block["tier_key"] == "bundle_20"
    assert block["status"] == SubscriptionStatus.ACTIVE
    assert block["tenants_used"] == 0
    assert block["tenant_limit"] == 20
    assert block["can_verify_nid"] is True
    # No sensitive billing data leaks into the block (§14).
    assert "monthly_price" not in block
    assert "annual_price" not in block
    assert "next_billing_at" not in block
    assert "start_at" not in block


def test_config_public_subscription_free_fallback(landlord: User) -> None:
    _set_free_limit(2)

    api = APIClient()
    api.force_authenticate(user=landlord)
    response = api.get(CONFIG_PUBLIC)
    assert response.status_code == 200

    block = response.json()["subscription"]
    assert block["tier_key"] == "free"
    assert block["status"] == SubscriptionStatus.ACTIVE
    assert block["tenant_limit"] == 2
    assert block["can_verify_nid"] is False


def test_config_public_cancelled_subscription_falls_back_to_free(
    landlord: User,
) -> None:
    _set_free_limit(2)
    tier = PricingTier.objects.get(key="bundle_20")
    SubscriptionFactory(
        user=landlord, tier=tier, status=SubscriptionStatus.CANCELLED
    )

    api = APIClient()
    api.force_authenticate(user=landlord)
    block = api.get(CONFIG_PUBLIC).json()["subscription"]

    # Status reflects the cancelled row, but benefits drop to free tier.
    assert block["tier_key"] == "bundle_20"
    assert block["status"] == SubscriptionStatus.CANCELLED
    assert block["tenant_limit"] == 2
    assert block["can_verify_nid"] is False
