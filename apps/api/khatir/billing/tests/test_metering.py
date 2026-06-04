"""Metering + free-limit enforcement tests (EPIC-10 T-003 §12).

Exercises ``check_tenant_limit`` and its wiring into tenant create:

* at the free limit minus one → create succeeds;
* at the free limit → create is blocked with the ``tier_limit_exceeded`` /
  ``402`` envelope;
* an active paid subscription with a higher ``tenant_max`` lets the same user
  past the free limit;
* an unlimited tier (``tenant_max = None``) never blocks;
* the limit is read from the ``free_tier_tenant_limit`` config, not hardcoded.

A tenant only counts toward the cap once it holds a lease on one of the user's
units (the ``Tenant.objects.for_user`` visibility chain), so the helpers lease
each counted tenant onto a building the landlord owns.
"""

from __future__ import annotations

import pytest
from rest_framework import status
from rest_framework.test import APIClient

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.billing.enums import SubscriptionStatus
from khatir.billing.services import FREE_TIER_LIMIT_KEY, check_tenant_limit
from khatir.billing.tests.factories import PricingTierFactory, SubscriptionFactory
from khatir.core.config import invalidate_config
from khatir.core.enums import ErrorCode
from khatir.core.exceptions import TierLimitExceeded
from khatir.core.models import SystemConfig
from khatir.leases.tests.factories import LeaseFactory
from khatir.properties.tests.factories import BuildingFactory, UnitFactory
from khatir.tenants.tests.factories import TenantFactory

pytestmark = pytest.mark.django_db


@pytest.fixture
def landlord() -> User:
    created: User = UserFactory(  # type: ignore[assignment]
        phone="+8801712345678", name="Landlord", role=Role.LANDLORD
    )
    return created


@pytest.fixture
def client(landlord: User) -> APIClient:
    api = APIClient()
    api.force_authenticate(user=landlord)
    return api


def _give_tenant(user: User) -> None:
    """Lease a fresh, countable tenant onto a unit in a building ``user`` owns."""
    tenant = TenantFactory()
    building = BuildingFactory(owner=user)
    unit = UnitFactory(building=building)
    LeaseFactory(unit=unit, tenant=tenant, landlord=user)


def _set_free_limit(value: int) -> None:
    SystemConfig.objects.update_or_create(
        key=FREE_TIER_LIMIT_KEY,
        defaults={"value": str(value), "type": "int", "description": "test"},
    )
    invalidate_config(FREE_TIER_LIMIT_KEY)


# --- service: free tier ------------------------------------------------------


def test_under_limit_ok(landlord: User) -> None:
    _give_tenant(landlord)  # 1 of 2 used
    # No exception => allowed to add one more.
    check_tenant_limit(landlord)


def test_at_limit_blocked(landlord: User) -> None:
    _give_tenant(landlord)
    _give_tenant(landlord)  # 2 of 2 used — adding a 3rd is over the free cap

    with pytest.raises(TierLimitExceeded) as exc:
        check_tenant_limit(landlord)

    assert exc.value.error_code == ErrorCode.TIER_LIMIT_EXCEEDED
    assert exc.value.status_code == status.HTTP_402_PAYMENT_REQUIRED
    assert exc.value.details == {"limit": 2, "tenants_used": 2}


def test_over_limit_blocked(landlord: User) -> None:
    for _ in range(3):
        _give_tenant(landlord)

    with pytest.raises(TierLimitExceeded):
        check_tenant_limit(landlord)


def test_limit_read_from_config_not_hardcoded(landlord: User) -> None:
    _set_free_limit(3)
    for _ in range(2):
        _give_tenant(landlord)

    # 2 of 3 used — still allowed because the limit comes from config.
    check_tenant_limit(landlord)

    _give_tenant(landlord)  # now 3 of 3
    with pytest.raises(TierLimitExceeded):
        check_tenant_limit(landlord)


# --- service: paid / upgraded tiers ------------------------------------------


def test_upgraded_tier_passes(landlord: User) -> None:
    """A paid tier with a higher cap lets the user past the free limit."""
    tier = PricingTierFactory(key="test_cap_20", tenant_max=20)
    SubscriptionFactory(user=landlord, tier=tier, status=SubscriptionStatus.ACTIVE)

    for _ in range(5):  # well past the free limit of 2
        _give_tenant(landlord)

    check_tenant_limit(landlord)  # no exception — within the 20-tenant cap


def test_unlimited_tier_never_blocks(landlord: User) -> None:
    tier = PricingTierFactory(key="test_unlimited", tenant_max=None)
    SubscriptionFactory(user=landlord, tier=tier, status=SubscriptionStatus.ACTIVE)

    for _ in range(5):
        _give_tenant(landlord)

    check_tenant_limit(landlord)


def test_paid_tier_still_enforces_its_cap(landlord: User) -> None:
    tier = PricingTierFactory(key="test_cap_3", tenant_max=3)
    SubscriptionFactory(user=landlord, tier=tier, status=SubscriptionStatus.ACTIVE)

    for _ in range(3):
        _give_tenant(landlord)

    with pytest.raises(TierLimitExceeded) as exc:
        check_tenant_limit(landlord)
    assert exc.value.details == {"limit": 3, "tenants_used": 3}


def test_cancelled_subscription_falls_back_to_free(landlord: User) -> None:
    """A cancelled paid plan does not grant its cap — back to the free tier."""
    tier = PricingTierFactory(key="test_cap_99", tenant_max=99)
    SubscriptionFactory(
        user=landlord, tier=tier, status=SubscriptionStatus.CANCELLED
    )

    for _ in range(2):
        _give_tenant(landlord)

    with pytest.raises(TierLimitExceeded):
        check_tenant_limit(landlord)


# --- wiring: tenant create endpoint ------------------------------------------


def test_create_under_limit_succeeds(client: APIClient, landlord: User) -> None:
    _give_tenant(landlord)  # 1 of 2

    resp = client.post(
        "/api/v1/tenants",
        {"name": "Rahim", "nid_number": "1990123456789"},
        format="json",
    )
    assert resp.status_code == status.HTTP_201_CREATED


def test_create_over_limit_returns_envelope(
    client: APIClient, landlord: User
) -> None:
    _give_tenant(landlord)
    _give_tenant(landlord)  # 2 of 2 — at the free cap

    resp = client.post(
        "/api/v1/tenants",
        {"name": "Karim", "nid_number": "1990123456789"},
        format="json",
    )

    assert resp.status_code == status.HTTP_402_PAYMENT_REQUIRED
    body = resp.json()
    assert body["error"]["code"] == ErrorCode.TIER_LIMIT_EXCEEDED.value
    assert body["error"]["details"] == {"limit": 2, "tenants_used": 2}


def test_create_blocked_then_no_tenant_persisted(
    client: APIClient, landlord: User
) -> None:
    from khatir.tenants.models import Tenant

    _give_tenant(landlord)
    _give_tenant(landlord)
    before = Tenant.objects.count()

    client.post(
        "/api/v1/tenants",
        {"name": "Blocked", "nid_number": "1990123456789"},
        format="json",
    )
    # The atomic create rolled back — nothing new landed.
    assert Tenant.objects.count() == before


def test_create_with_paid_tier_succeeds(
    client: APIClient, landlord: User
) -> None:
    tier = PricingTierFactory(key="test_paid_20", tenant_max=20)
    SubscriptionFactory(user=landlord, tier=tier, status=SubscriptionStatus.ACTIVE)
    for _ in range(3):  # past the free limit
        _give_tenant(landlord)

    resp = client.post(
        "/api/v1/tenants",
        {"name": "Extra", "nid_number": "1990123456789"},
        format="json",
    )
    assert resp.status_code == status.HTTP_201_CREATED
