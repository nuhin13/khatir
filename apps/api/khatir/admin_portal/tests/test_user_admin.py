"""Tests for the admin-portal user management endpoints (EPIC-12.T-003 §12).

Covers: search (phone / name / id / masked-NID), full detail payload, suspend
(``is_active=False`` + refresh-token blacklist + mandatory reason), reactivate,
manual subscription upgrade, admin audit of every action, and the role gate
(super/ops/support read; only super/ops may write).

Admin auth here is the dedicated admin JWT realm; the user JWTs being
invalidated belong to the *customer* simplejwt realm — two separate worlds.
"""

from __future__ import annotations

import pytest
from rest_framework.test import APIClient
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.token_blacklist.models import (
    BlacklistedToken,
    OutstandingToken,
)
from rest_framework_simplejwt.tokens import RefreshToken

from khatir.accounts.auth_tokens import issue_tokens
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.admin_portal.auth_tokens import issue_access_token
from khatir.admin_portal.models import AdminAuditEntry
from khatir.admin_portal.tests.factories import AdminUserFactory
from khatir.billing.enums import SubscriptionStatus
from khatir.billing.models import Subscription
from khatir.billing.tests.factories import PricingTierFactory, SubscriptionFactory
from khatir.core.enums import AdminRole, Role
from khatir.tenants.tests.factories import TenantFactory

pytestmark = pytest.mark.django_db

USERS_URL = "/admin/api/users"


def _auth_client(role: str = AdminRole.OPS) -> APIClient:
    admin = AdminUserFactory(role=role)
    token, _ = issue_access_token(admin.pk, admin.role)
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    return client


# --- Search -----------------------------------------------------------------


def test_search_by_phone() -> None:
    UserFactory(phone="+8801711110000", name="Alpha")
    UserFactory(phone="+8801722220000", name="Beta")

    body = _auth_client().get(USERS_URL, {"q": "1711110000"}).json()
    names = [row["name"] for row in body["results"]]
    assert names == ["Alpha"]


def test_search_by_name() -> None:
    UserFactory(name="Karim Uddin")
    UserFactory(name="Rahim Mia")

    body = _auth_client().get(USERS_URL, {"q": "karim"}).json()
    assert [row["name"] for row in body["results"]] == ["Karim Uddin"]


def test_search_by_id() -> None:
    target = UserFactory(name="ById")
    UserFactory(name="Other")

    body = _auth_client().get(USERS_URL, {"q": str(target.pk)}).json()
    ids = [row["id"] for row in body["results"]]
    assert target.pk in ids


def test_search_by_masked_nid() -> None:
    landlord = UserFactory(name="NID Owner")
    TenantFactory(linked_user=landlord, nid_number_masked="****7788")

    body = _auth_client().get(USERS_URL, {"q": "7788"}).json()
    assert any(row["id"] == landlord.pk for row in body["results"])


def test_search_is_paginated() -> None:
    body = _auth_client().get(USERS_URL).json()
    assert "results" in body
    assert "pagination" in body
    assert {"next", "previous", "count"} <= set(body["pagination"])


# --- Detail -----------------------------------------------------------------


def test_detail_payload() -> None:
    user = UserFactory(role=Role.LANDLORD)
    SubscriptionFactory(user=user)

    body = _auth_client().get(f"{USERS_URL}/{user.pk}").json()
    assert body["user"]["id"] == user.pk
    assert body["subscription"]["status"] == SubscriptionStatus.ACTIVE
    assert "usage" in body
    assert "audit_trail" in body


def test_detail_404_for_missing_user() -> None:
    resp = _auth_client().get(f"{USERS_URL}/999999")
    assert resp.status_code == 404


# --- Suspend (is_active + JWT invalidation + audit) -------------------------


def test_suspend_requires_reason() -> None:
    user = UserFactory()
    resp = _auth_client().post(f"{USERS_URL}/{user.pk}/suspend", {}, format="json")
    assert resp.status_code == 400


def test_suspend_deactivates_and_blacklists_jwt() -> None:
    user = User.objects.create_user(
        phone="+8801799990000", name="ToSuspend", role=Role.LANDLORD
    )
    # Mint a customer token pair so there is an outstanding refresh token.
    tokens = issue_tokens(user)
    assert OutstandingToken.objects.filter(user=user).exists()

    resp = _auth_client().post(
        f"{USERS_URL}/{user.pk}/suspend",
        {"reason": "Fraudulent activity"},
        format="json",
    )
    assert resp.status_code == 200

    user.refresh_from_db()
    assert user.is_active is False

    # Every outstanding refresh token is now blacklisted -> cannot re-mint.
    outstanding = OutstandingToken.objects.filter(user=user)
    assert outstanding.exists()
    for token in outstanding:
        assert BlacklistedToken.objects.filter(token=token).exists()

    # The blacklisted refresh token is rejected on verification, so it can no
    # longer be used to mint a fresh access token.
    with pytest.raises(TokenError):
        RefreshToken(tokens["refresh"])  # type: ignore[arg-type]


def test_suspend_audited() -> None:
    user = UserFactory()
    _auth_client().post(
        f"{USERS_URL}/{user.pk}/suspend",
        {"reason": "Policy breach"},
        format="json",
    )
    entry = AdminAuditEntry.objects.filter(
        action="user.suspend", entity_id=str(user.pk)
    ).first()
    assert entry is not None
    assert entry.reason == "Policy breach"
    assert entry.before_json == {"is_active": True}
    assert entry.after_json["is_active"] is False


def test_suspend_already_suspended_conflicts() -> None:
    user = UserFactory(is_active=False)
    resp = _auth_client().post(
        f"{USERS_URL}/{user.pk}/suspend", {"reason": "x"}, format="json"
    )
    assert resp.status_code == 409


# --- Reactivate -------------------------------------------------------------


def test_reactivate_reenables_user() -> None:
    user = UserFactory(is_active=False)
    resp = _auth_client().post(
        f"{USERS_URL}/{user.pk}/reactivate", {}, format="json"
    )
    assert resp.status_code == 200
    user.refresh_from_db()
    assert user.is_active is True


def test_reactivate_audited() -> None:
    user = UserFactory(is_active=False)
    _auth_client().post(f"{USERS_URL}/{user.pk}/reactivate", {}, format="json")
    assert AdminAuditEntry.objects.filter(
        action="user.reactivate", entity_id=str(user.pk)
    ).exists()


def test_reactivate_already_active_conflicts() -> None:
    user = UserFactory(is_active=True)
    resp = _auth_client().post(
        f"{USERS_URL}/{user.pk}/reactivate", {}, format="json"
    )
    assert resp.status_code == 409


# --- Upgrade subscription ---------------------------------------------------


def test_upgrade_existing_subscription() -> None:
    user = UserFactory()
    sub = SubscriptionFactory(user=user)
    new_tier = PricingTierFactory(key="comp_tier_xyz")

    resp = _auth_client().post(
        f"{USERS_URL}/{user.pk}/upgrade-subscription",
        {"tier_id": new_tier.pk, "reason": "Comp upgrade"},
        format="json",
    )
    assert resp.status_code == 200
    sub.refresh_from_db()
    assert sub.tier_id == new_tier.pk
    assert AdminAuditEntry.objects.filter(
        action="user.upgrade_subscription", entity_id=str(user.pk)
    ).exists()


def test_upgrade_creates_subscription_when_none() -> None:
    user = UserFactory()
    tier = PricingTierFactory(key="manual_grant_tier")

    resp = _auth_client().post(
        f"{USERS_URL}/{user.pk}/upgrade-subscription",
        {"tier_id": tier.pk, "reason": "Manual grant"},
        format="json",
    )
    assert resp.status_code == 200
    assert Subscription.objects.filter(user=user, tier=tier).exists()


def test_upgrade_requires_reason() -> None:
    user = UserFactory()
    tier = PricingTierFactory()
    resp = _auth_client().post(
        f"{USERS_URL}/{user.pk}/upgrade-subscription",
        {"tier_id": tier.pk},
        format="json",
    )
    assert resp.status_code == 400


def test_upgrade_unknown_tier_404() -> None:
    user = UserFactory()
    resp = _auth_client().post(
        f"{USERS_URL}/{user.pk}/upgrade-subscription",
        {"tier_id": 999999, "reason": "x"},
        format="json",
    )
    assert resp.status_code == 404


# --- Role gate --------------------------------------------------------------


def test_anonymous_denied() -> None:
    assert APIClient().get(USERS_URL).status_code in (401, 403)


@pytest.mark.parametrize("role", [AdminRole.SUPER, AdminRole.OPS, AdminRole.SUPPORT])
def test_read_roles_allowed(role: str) -> None:
    assert _auth_client(role).get(USERS_URL).status_code == 200


@pytest.mark.parametrize("role", [AdminRole.FINANCE, AdminRole.COMPLIANCE])
def test_non_users_roles_denied_read(role: str) -> None:
    assert _auth_client(role).get(USERS_URL).status_code == 403


def test_support_cannot_write() -> None:
    user = UserFactory()
    resp = _auth_client(AdminRole.SUPPORT).post(
        f"{USERS_URL}/{user.pk}/suspend", {"reason": "x"}, format="json"
    )
    assert resp.status_code == 403


@pytest.mark.parametrize("role", [AdminRole.SUPER, AdminRole.OPS])
def test_ops_super_can_write(role: str) -> None:
    user = UserFactory()
    resp = _auth_client(role).post(
        f"{USERS_URL}/{user.pk}/suspend", {"reason": "ok"}, format="json"
    )
    assert resp.status_code == 200


def test_disabled_admin_denied() -> None:
    admin = AdminUserFactory(role=AdminRole.OPS, disabled=True)
    token, _ = issue_access_token(admin.pk, admin.role)
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    assert client.get(USERS_URL).status_code in (401, 403)
