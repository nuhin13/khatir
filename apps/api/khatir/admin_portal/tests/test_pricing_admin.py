"""Tests for the admin-portal pricing-tier endpoints (EPIC-12.T-001 §12).

Covers: list all tiers, read-only impact preview (subscribers affected +
monthly revenue delta), PATCH edit (reason required, before/after audit, value
applied, ``/config/public`` cache busted), and the role gate (only finance and
super may reach the section; other admin roles and anonymous are denied).

Admin auth here is the dedicated admin JWT realm — separate from the customer
realm — exactly as in the user-management tests.
"""

from __future__ import annotations

from decimal import Decimal
from unittest import mock

import pytest
from rest_framework.test import APIClient

from khatir.admin_portal.auth_tokens import issue_access_token
from khatir.admin_portal.models import AdminAuditEntry
from khatir.admin_portal.tests.factories import AdminUserFactory
from khatir.billing.enums import BillingCycle, SubscriptionStatus
from khatir.billing.tests.factories import PricingTierFactory, SubscriptionFactory
from khatir.core.enums import AdminRole

pytestmark = pytest.mark.django_db

TIERS_URL = "/admin/api/pricing/tiers"


def _auth_client(role: str = AdminRole.FINANCE) -> APIClient:
    admin = AdminUserFactory(role=role)
    token, _ = issue_access_token(admin.pk, admin.role)
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    return client


# --- List -------------------------------------------------------------------


def test_list_returns_all_tiers() -> None:
    PricingTierFactory(key="free_t", sort_order=10, active=True)
    PricingTierFactory(key="paid_t", sort_order=20, active=False)

    body = _auth_client().get(TIERS_URL).json()
    keys = [row["key"] for row in body]
    # Both the active and inactive tier are present (admin sees everything).
    assert "free_t" in keys
    assert "paid_t" in keys
    # Ordered by sort_order ascending, so free_t precedes paid_t.
    assert keys.index("free_t") < keys.index("paid_t")
    assert "monthly_price" in body[0]
    assert "active" in body[0]


# --- Preview (read-only) ----------------------------------------------------


def test_preview_counts_active_subscribers_and_delta() -> None:
    tier = PricingTierFactory(key="prev_t", monthly_price=Decimal("100.00"))
    SubscriptionFactory(
        tier=tier, billing_cycle=BillingCycle.MONTHLY, status=SubscriptionStatus.ACTIVE
    )
    SubscriptionFactory(
        tier=tier, billing_cycle=BillingCycle.MONTHLY, status=SubscriptionStatus.ACTIVE
    )
    # A cancelled subscriber is not "affected".
    SubscriptionFactory(
        tier=tier,
        billing_cycle=BillingCycle.MONTHLY,
        status=SubscriptionStatus.CANCELLED,
    )

    resp = _auth_client().post(
        f"{TIERS_URL}/{tier.key}/preview",
        {"monthly_price": "150.00"},
        format="json",
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["subscribers_affected"] == 2
    # +50 per monthly subscriber x2 = +100.00
    assert Decimal(body["monthly_revenue_delta"]) == Decimal("100.00")


def test_preview_does_not_write() -> None:
    tier = PricingTierFactory(key="prev_nw", monthly_price=Decimal("100.00"))
    _auth_client().post(
        f"{TIERS_URL}/{tier.key}/preview",
        {"monthly_price": "200.00"},
        format="json",
    )
    tier.refresh_from_db()
    assert tier.monthly_price == Decimal("100.00")  # unchanged


def test_preview_annual_subscriber_amortised() -> None:
    tier = PricingTierFactory(
        key="prev_an",
        monthly_price=Decimal("100.00"),
        annual_price=Decimal("1200.00"),
    )
    SubscriptionFactory(
        tier=tier, billing_cycle=BillingCycle.ANNUAL, status=SubscriptionStatus.ACTIVE
    )
    body = _auth_client().post(
        f"{TIERS_URL}/{tier.key}/preview",
        {"annual_price": "2400.00"},
        format="json",
    ).json()
    # annual goes 1200 -> 2400, monthly equivalent 100 -> 200, delta +100.00
    assert body["subscribers_affected"] == 1
    assert Decimal(body["monthly_revenue_delta"]) == Decimal("100.00")


def test_preview_unknown_tier_404() -> None:
    resp = _auth_client().post(
        f"{TIERS_URL}/nope/preview", {"monthly_price": "1"}, format="json"
    )
    assert resp.status_code == 404


# --- Edit (PATCH) -----------------------------------------------------------


def test_edit_applies_changes() -> None:
    tier = PricingTierFactory(key="edit_t", monthly_price=Decimal("100.00"))
    resp = _auth_client().patch(
        f"{TIERS_URL}/{tier.key}",
        {"monthly_price": "250.00", "reason": "Annual price review"},
        format="json",
    )
    assert resp.status_code == 200
    tier.refresh_from_db()
    assert tier.monthly_price == Decimal("250.00")


def test_edit_requires_reason() -> None:
    tier = PricingTierFactory(key="edit_nr")
    resp = _auth_client().patch(
        f"{TIERS_URL}/{tier.key}", {"monthly_price": "5.00"}, format="json"
    )
    assert resp.status_code == 400


def test_edit_writes_before_after_audit() -> None:
    tier = PricingTierFactory(key="edit_au", monthly_price=Decimal("100.00"))
    _auth_client().patch(
        f"{TIERS_URL}/{tier.key}",
        {"monthly_price": "300.00", "reason": "Repricing"},
        format="json",
    )
    entry = AdminAuditEntry.objects.filter(
        action="pricing.tier.edit", entity_id=str(tier.pk)
    ).first()
    assert entry is not None
    assert entry.reason == "Repricing"
    assert entry.before_json == {"monthly_price": "100.00"}
    assert entry.after_json == {"monthly_price": "300.00"}


def test_edit_busts_public_config_cache() -> None:
    tier = PricingTierFactory(key="edit_cache", monthly_price=Decimal("100.00"))
    with mock.patch(
        "khatir.admin_portal.pricing_services.invalidate_public_config_cache"
    ) as bust:
        _auth_client().patch(
            f"{TIERS_URL}/{tier.key}",
            {"monthly_price": "120.00", "reason": "tweak"},
            format="json",
        )
    bust.assert_called_once()


def test_edit_unknown_tier_404() -> None:
    resp = _auth_client().patch(
        f"{TIERS_URL}/missing", {"monthly_price": "1", "reason": "x"}, format="json"
    )
    assert resp.status_code == 404


# --- Role gate --------------------------------------------------------------


def test_anonymous_denied() -> None:
    assert APIClient().get(TIERS_URL).status_code in (401, 403)


@pytest.mark.parametrize("role", [AdminRole.SUPER, AdminRole.FINANCE])
def test_pricing_roles_allowed(role: str) -> None:
    assert _auth_client(role).get(TIERS_URL).status_code == 200


@pytest.mark.parametrize(
    "role", [AdminRole.OPS, AdminRole.COMPLIANCE, AdminRole.SUPPORT]
)
def test_non_pricing_roles_denied(role: str) -> None:
    tier = PricingTierFactory(key=f"gate_{role}")
    client = _auth_client(role)
    assert client.get(TIERS_URL).status_code == 403
    assert (
        client.patch(
            f"{TIERS_URL}/{tier.key}",
            {"monthly_price": "1", "reason": "x"},
            format="json",
        ).status_code
        == 403
    )


def test_disabled_admin_denied() -> None:
    admin = AdminUserFactory(role=AdminRole.FINANCE, disabled=True)
    token, _ = issue_access_token(admin.pk, admin.role)
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    assert client.get(TIERS_URL).status_code in (401, 403)
