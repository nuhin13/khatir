"""API tests for the subscription endpoints (T-004 §12).

Exercises ``GET /api/v1/billing/subscription`` and ``POST /api/v1/billing/subscribe``
through DRF's ``APIClient`` with a real authenticated landlord. Covers subscribe
(new), upgrade (existing → new tier), inactive-tier rejection, the stubbed
payment intent on paid tiers, and that every mutation is audited.
"""

from __future__ import annotations

import pytest
from rest_framework import status
from rest_framework.test import APIClient

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.billing.enums import SubscriptionStatus
from khatir.billing.models import Subscription
from khatir.billing.tests.factories import PricingTierFactory, SubscriptionFactory
from khatir.core.models import AuditEntry

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


# --- subscribe (new) ---------------------------------------------------------


def test_subscribe(client: APIClient, landlord: User) -> None:
    tier = PricingTierFactory(key="bundle_10", tenant_max=10, monthly_price=None)

    resp = client.post(
        "/api/v1/billing/subscribe", {"tier_key": "bundle_10"}, format="json"
    )

    assert resp.status_code == status.HTTP_201_CREATED
    body = resp.json()
    assert body["tier"]["key"] == "bundle_10"
    assert body["status"] == SubscriptionStatus.ACTIVE
    assert body["tenants_limit"] == 10
    assert body["tenants_used"] == 0

    sub = Subscription.objects.get(user=landlord)
    assert sub.tier == tier
    assert sub.status == SubscriptionStatus.ACTIVE
    assert AuditEntry.objects.filter(action="subscription.create").exists()


def test_subscribe_paid_tier_records_payment_intent(
    client: APIClient, landlord: User
) -> None:
    PricingTierFactory(key="paid_plan", tenant_max=20, monthly_price="500.00")

    resp = client.post(
        "/api/v1/billing/subscribe", {"tier_key": "paid_plan"}, format="json"
    )

    assert resp.status_code == status.HTTP_201_CREATED
    # Payment is stubbed: a pending intent marker is recorded, not a charge.
    intent = AuditEntry.objects.get(action="subscription.payment_intent")
    assert intent.after is not None
    assert intent.after["state"] == "pending"
    assert intent.after["provider"] == "mfs"


# --- upgrade (existing) ------------------------------------------------------


def test_upgrade(client: APIClient, landlord: User) -> None:
    old_tier = PricingTierFactory(key="bundle_10", tenant_max=10)
    SubscriptionFactory(user=landlord, tier=old_tier)
    new_tier = PricingTierFactory(key="bundle_50", tenant_max=50)

    resp = client.post(
        "/api/v1/billing/subscribe", {"tier_key": "bundle_50"}, format="json"
    )

    assert resp.status_code == status.HTTP_201_CREATED
    body = resp.json()
    assert body["tier"]["key"] == "bundle_50"
    assert body["tenants_limit"] == 50

    # Upgraded in place — still a single subscription row for the user.
    assert Subscription.objects.filter(user=landlord).count() == 1
    sub = Subscription.objects.get(user=landlord)
    assert sub.tier == new_tier
    assert AuditEntry.objects.filter(action="subscription.upgrade").exists()


# --- inactive tier rejected --------------------------------------------------


def test_inactive_tier_rejected(client: APIClient, landlord: User) -> None:
    PricingTierFactory(key="legacy_plan", active=False)

    resp = client.post(
        "/api/v1/billing/subscribe", {"tier_key": "legacy_plan"}, format="json"
    )

    assert resp.status_code == status.HTTP_400_BAD_REQUEST
    assert resp.json()["error"]["code"] == "validation_error"
    assert not Subscription.objects.filter(user=landlord).exists()


def test_unknown_tier_rejected(client: APIClient, landlord: User) -> None:
    resp = client.post(
        "/api/v1/billing/subscribe", {"tier_key": "does_not_exist"}, format="json"
    )

    assert resp.status_code == status.HTTP_400_BAD_REQUEST
    assert resp.json()["error"]["code"] == "validation_error"


# --- GET current subscription ------------------------------------------------


def test_get_subscription_returns_plan_and_usage(
    client: APIClient, landlord: User
) -> None:
    tier = PricingTierFactory(key="bundle_10", tenant_max=10)
    SubscriptionFactory(user=landlord, tier=tier)

    resp = client.get("/api/v1/billing/subscription")

    assert resp.status_code == status.HTTP_200_OK
    body = resp.json()
    assert body["tier"]["key"] == "bundle_10"
    assert body["tenants_limit"] == 10
    assert body["tenants_used"] == 0


def test_get_subscription_no_subscription_is_204(
    client: APIClient, landlord: User
) -> None:
    resp = client.get("/api/v1/billing/subscription")
    assert resp.status_code == status.HTTP_204_NO_CONTENT


def test_get_unlimited_tier_reports_null_limit(
    client: APIClient, landlord: User
) -> None:
    tier = PricingTierFactory(key="unlimited", tenant_max=None)
    SubscriptionFactory(user=landlord, tier=tier)

    resp = client.get("/api/v1/billing/subscription")

    assert resp.status_code == status.HTTP_200_OK
    assert resp.json()["tenants_limit"] is None


# --- auth / role gating ------------------------------------------------------


def test_subscribe_requires_auth() -> None:
    anon = APIClient()
    resp = anon.post(
        "/api/v1/billing/subscribe", {"tier_key": "free"}, format="json"
    )
    assert resp.status_code in (
        status.HTTP_401_UNAUTHORIZED,
        status.HTTP_403_FORBIDDEN,
    )
