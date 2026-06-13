"""Tests for the admin-portal refund queue endpoints (EPIC-12.T-004 §12).

Covers: the pending-intent queue, approve (records a ``refunded`` resolution +
cancels the subscription + admin audit), deny (mandatory reason + records a
``refund_denied`` resolution, subscription untouched), the once-only guard, and
the finance/super role gate.

Refunds have no dedicated table for the MVP — they are the EPIC-10 stub's
customer-realm ``subscription.payment_intent`` audit entries. The admin realm
here is the dedicated admin JWT; the intents being resolved live in the
customer-realm :class:`AuditEntry` table — two separate worlds.
"""

from __future__ import annotations

import pytest
from rest_framework.test import APIClient

from khatir.admin_portal.auth_tokens import issue_access_token
from khatir.admin_portal.models import AdminAuditEntry
from khatir.admin_portal.refund_views import PAYMENT_INTENT_ACTION
from khatir.admin_portal.tests.factories import AdminUserFactory
from khatir.billing.enums import SubscriptionStatus
from khatir.billing.tests.factories import PricingTierFactory, SubscriptionFactory
from khatir.core.audit import audit
from khatir.core.enums import AdminRole
from khatir.core.models import AuditEntry

pytestmark = pytest.mark.django_db

REFUNDS_URL = "/admin/api/billing/refunds"


def _auth_client(role: str = AdminRole.FINANCE) -> APIClient:
    admin = AdminUserFactory(role=role)
    token, _ = issue_access_token(admin.pk, admin.role)
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    return client


def _pending_intent(tier_key: str | None = None) -> AuditEntry:
    """Create a pending payment intent like the EPIC-10 subscribe stub does."""
    kwargs: dict[str, object] = {"monthly_price": 500}
    if tier_key is not None:
        kwargs["key"] = tier_key
    tier = PricingTierFactory(**kwargs)
    subscription = SubscriptionFactory(tier=tier)
    return audit(
        actor=subscription.user,
        action=PAYMENT_INTENT_ACTION,
        target=subscription,
        before=None,
        after={
            "tier_key": tier.key,
            "billing_cycle": subscription.billing_cycle,
            "provider": "mfs",
            "state": "pending",
        },
    )


# --- Queue ------------------------------------------------------------------


def test_refund_list() -> None:
    intent = _pending_intent("refund_tier_xyz")
    body = _auth_client().get(REFUNDS_URL).json()
    ids = [row["id"] for row in body["results"]]
    assert intent.pk in ids
    row = next(r for r in body["results"] if r["id"] == intent.pk)
    assert row["tier_key"] == "refund_tier_xyz"
    assert row["state"] == "pending"
    assert row["subscription_id"] is not None


def test_list_excludes_resolved_intents() -> None:
    intent = _pending_intent()
    _auth_client().post(
        f"{REFUNDS_URL}/{intent.pk}/process", {"approve": True}, format="json"
    )
    body = _auth_client().get(REFUNDS_URL).json()
    assert intent.pk not in [row["id"] for row in body["results"]]


# --- Approve ----------------------------------------------------------------


def test_approve() -> None:
    intent = _pending_intent()
    sub_id = int(intent.target_id)

    resp = _auth_client().post(
        f"{REFUNDS_URL}/{intent.pk}/process", {"approve": True}, format="json"
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["decision"] == "approved"
    assert body["state"] == "refunded"
    assert body["subscription_status"] == SubscriptionStatus.CANCELLED

    # A resolution entry now references the original intent.
    assert AuditEntry.objects.filter(
        action=PAYMENT_INTENT_ACTION, after__resolves=intent.pk, after__state="refunded"
    ).exists()
    # The subscription is cancelled.
    from khatir.billing.models import Subscription

    assert Subscription.objects.get(pk=sub_id).status == SubscriptionStatus.CANCELLED


# --- Deny -------------------------------------------------------------------


def test_deny() -> None:
    intent = _pending_intent()
    sub_id = int(intent.target_id)

    resp = _auth_client().post(
        f"{REFUNDS_URL}/{intent.pk}/process",
        {"approve": False, "reason": "Outside refund window"},
        format="json",
    )
    assert resp.status_code == 200
    assert resp.json()["state"] == "refund_denied"

    assert AuditEntry.objects.filter(
        action=PAYMENT_INTENT_ACTION,
        after__resolves=intent.pk,
        after__state="refund_denied",
    ).exists()
    # Subscription is left untouched on a denial.
    from khatir.billing.models import Subscription

    assert Subscription.objects.get(pk=sub_id).status == SubscriptionStatus.ACTIVE


def test_deny_requires_reason() -> None:
    intent = _pending_intent()
    resp = _auth_client().post(
        f"{REFUNDS_URL}/{intent.pk}/process", {"approve": False}, format="json"
    )
    assert resp.status_code == 400


# --- Audit ------------------------------------------------------------------


def test_audit() -> None:
    intent = _pending_intent()
    _auth_client().post(
        f"{REFUNDS_URL}/{intent.pk}/process",
        {"approve": False, "reason": "No proof of charge"},
        format="json",
    )
    entry = AdminAuditEntry.objects.filter(action="refund.process").first()
    assert entry is not None
    assert entry.reason == "No proof of charge"
    assert entry.after_json["decision"] == "denied"


# --- Once-only guard --------------------------------------------------------


def test_process_twice_conflicts() -> None:
    intent = _pending_intent()
    client = _auth_client()
    first = client.post(
        f"{REFUNDS_URL}/{intent.pk}/process", {"approve": True}, format="json"
    )
    assert first.status_code == 200
    second = client.post(
        f"{REFUNDS_URL}/{intent.pk}/process", {"approve": True}, format="json"
    )
    assert second.status_code == 409


def test_process_unknown_404() -> None:
    resp = _auth_client().post(
        f"{REFUNDS_URL}/999999/process", {"approve": True}, format="json"
    )
    assert resp.status_code == 404


# --- Role gate --------------------------------------------------------------


def test_anonymous_denied() -> None:
    assert APIClient().get(REFUNDS_URL).status_code in (401, 403)


@pytest.mark.parametrize("role", [AdminRole.FINANCE, AdminRole.SUPER])
def test_finance_super_allowed(role: str) -> None:
    assert _auth_client(role).get(REFUNDS_URL).status_code == 200


@pytest.mark.parametrize(
    "role", [AdminRole.OPS, AdminRole.SUPPORT, AdminRole.COMPLIANCE]
)
def test_other_roles_denied(role: str) -> None:
    assert _auth_client(role).get(REFUNDS_URL).status_code == 403


def test_non_finance_cannot_process() -> None:
    intent = _pending_intent()
    resp = _auth_client(AdminRole.OPS).post(
        f"{REFUNDS_URL}/{intent.pk}/process", {"approve": True}, format="json"
    )
    assert resp.status_code == 403
