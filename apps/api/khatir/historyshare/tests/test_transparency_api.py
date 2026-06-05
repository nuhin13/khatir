"""Tests for the tenant transparency + revoke endpoints (EPIC-24.T-004 §12).

Exercises:

* ``GET  /api/v1/me/history-shares`` — the owning tenant sees ALL their shares
  (what / who / when / status), scoped to themselves only;
* ``POST /api/v1/me/history-shares/{id}/revoke`` — the tenant revokes a share
  instantly, the linked consent is withdrawn, it is audited, idempotent, and
  another tenant's share is 404 (never 403 — existence never leaks);
* revoke remains available even when the kill-switch is off (a tenant must
  always be able to withdraw consent).
"""

from __future__ import annotations

import datetime

import pytest
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APIClient

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.compliance.tests.factories import ConsentRecordFactory
from khatir.core.models import AuditEntry
from khatir.featureflags.enums import FlagScope
from khatir.featureflags.models import FeatureFlag
from khatir.historyshare.flags import HISTORY_FLAGS_FEATURE
from khatir.historyshare.models import HistoryShare
from khatir.historyshare.tests.factories import HistoryShareFactory
from khatir.tenants.tests.factories import TenantFactory

pytestmark = pytest.mark.django_db

LIST_URL = "/api/v1/me/history-shares"


def _revoke_url(share_id: int) -> str:
    return f"/api/v1/me/history-shares/{share_id}/revoke"


def _set_kill_switch(*, enabled: bool) -> None:
    FeatureFlag.objects.update_or_create(
        key=HISTORY_FLAGS_FEATURE,
        defaults={"scope": FlagScope.GLOBAL, "enabled": enabled},
    )


@pytest.fixture
def landlord() -> User:
    created: User = UserFactory(  # type: ignore[assignment]
        phone="+8801700000001", name="Landlord", role=Role.LANDLORD
    )
    return created


@pytest.fixture
def tenant_user() -> User:
    created: User = UserFactory(  # type: ignore[assignment]
        phone="+8801700000002", name="Tenant", role=Role.TENANT
    )
    return created


@pytest.fixture
def linked_tenant(tenant_user: User) -> object:
    return TenantFactory(linked_user=tenant_user)


@pytest.fixture
def client(tenant_user: User) -> APIClient:
    api = APIClient()
    api.force_authenticate(user=tenant_user)
    return api


# --- list / transparency -----------------------------------------------------


def test_tenant_lists_own_shares_with_status(
    client: APIClient, landlord: User, linked_tenant: object
) -> None:
    active = HistoryShareFactory(tenant=linked_tenant, recipient_landlord=landlord)
    revoked = HistoryShareFactory(
        tenant=linked_tenant, revoked_at=timezone.now()
    )
    expired = HistoryShareFactory(
        tenant=linked_tenant,
        expires_at=timezone.now() - datetime.timedelta(days=1),
    )

    resp = client.get(LIST_URL)
    assert resp.status_code == status.HTTP_200_OK
    body = resp.json()
    assert len(body) == 3
    by_id = {row["id"]: row for row in body}
    assert by_id[active.pk]["status"] == "active"
    assert by_id[revoked.pk]["status"] == "revoked"
    assert by_id[expired.pk]["status"] == "expired"
    # what / who / when are all present.
    assert by_id[active.pk]["recipient_landlord"] == landlord.pk
    assert "scope" in by_id[active.pk]
    assert "factual_stats" in by_id[active.pk]
    assert "created_at" in by_id[active.pk]


def test_list_is_scoped_to_caller(
    client: APIClient, linked_tenant: object
) -> None:
    HistoryShareFactory(tenant=linked_tenant)
    # Another tenant's share must never appear.
    other_tenant = TenantFactory()
    HistoryShareFactory(tenant=other_tenant)

    body = client.get(LIST_URL).json()
    assert len(body) == 1


def test_list_no_subjective_field(
    client: APIClient, linked_tenant: object
) -> None:
    HistoryShareFactory(
        tenant=linked_tenant,
        factual_stats={
            "on_time_payment_count": 5,
            "total_payments": 5,
            "lease_completed": True,
        },
    )
    body = client.get(LIST_URL).json()
    forbidden = {"rating", "score", "opinion", "review", "comment", "stars"}
    assert set(body[0]).isdisjoint(forbidden)
    assert set(body[0]["factual_stats"]).isdisjoint(forbidden)


def test_list_requires_tenant_role(landlord: User) -> None:
    api = APIClient()
    api.force_authenticate(user=landlord)
    resp = api.get(LIST_URL)
    assert resp.status_code in (
        status.HTTP_401_UNAUTHORIZED,
        status.HTTP_403_FORBIDDEN,
    )


def test_list_requires_auth() -> None:
    resp = APIClient().get(LIST_URL)
    assert resp.status_code in (
        status.HTTP_401_UNAUTHORIZED,
        status.HTTP_403_FORBIDDEN,
    )


# --- revoke ------------------------------------------------------------------


def test_tenant_revokes_share(
    client: APIClient, linked_tenant: object
) -> None:
    share: HistoryShare = HistoryShareFactory(  # type: ignore[assignment]
        tenant=linked_tenant
    )
    assert share.revoked_at is None

    resp = client.post(_revoke_url(share.pk))
    assert resp.status_code == status.HTTP_200_OK
    assert resp.json()["status"] == "revoked"

    share.refresh_from_db()
    assert share.revoked_at is not None
    # The recipient read path is now closed.
    assert share.is_readable() is False


def test_revoke_withdraws_consent(
    client: APIClient, linked_tenant: object
) -> None:
    consent = ConsentRecordFactory()
    share: HistoryShare = HistoryShareFactory(  # type: ignore[assignment]
        tenant=linked_tenant, consent_record=consent
    )
    client.post(_revoke_url(share.pk))
    consent.refresh_from_db()
    assert consent.revoked_at is not None


def test_revoke_is_audited(
    client: APIClient, linked_tenant: object
) -> None:
    share: HistoryShare = HistoryShareFactory(  # type: ignore[assignment]
        tenant=linked_tenant
    )
    client.post(_revoke_url(share.pk))
    assert AuditEntry.objects.filter(action="history_share.revoke").exists()


def test_revoke_is_idempotent(
    client: APIClient, linked_tenant: object
) -> None:
    share: HistoryShare = HistoryShareFactory(  # type: ignore[assignment]
        tenant=linked_tenant
    )
    first = client.post(_revoke_url(share.pk))
    assert first.status_code == status.HTTP_200_OK
    revoked_at = first.json()["revoked_at"]

    second = client.post(_revoke_url(share.pk))
    assert second.status_code == status.HTTP_200_OK
    # Original revoked_at preserved — re-revoking is a no-op.
    assert second.json()["revoked_at"] == revoked_at


def test_cannot_revoke_another_tenants_share_404(
    client: APIClient, linked_tenant: object
) -> None:
    other_tenant = TenantFactory()
    share: HistoryShare = HistoryShareFactory(  # type: ignore[assignment]
        tenant=other_tenant
    )
    resp = client.post(_revoke_url(share.pk))
    # 404, never 403 — another tenant's share existence must never leak.
    assert resp.status_code == status.HTTP_404_NOT_FOUND
    share.refresh_from_db()
    assert share.revoked_at is None


def test_revoke_unknown_share_404(
    client: APIClient, linked_tenant: object
) -> None:
    resp = client.post(_revoke_url(999999))
    assert resp.status_code == status.HTTP_404_NOT_FOUND


def test_revoke_requires_tenant_role(landlord: User) -> None:
    share: HistoryShare = HistoryShareFactory()  # type: ignore[assignment]
    api = APIClient()
    api.force_authenticate(user=landlord)
    resp = api.post(_revoke_url(share.pk))
    assert resp.status_code in (
        status.HTTP_401_UNAUTHORIZED,
        status.HTTP_403_FORBIDDEN,
    )


def test_revoke_works_even_when_kill_switch_off(
    client: APIClient, linked_tenant: object
) -> None:
    """Withdrawing consent must always be possible — even with the feature off."""
    share: HistoryShare = HistoryShareFactory(  # type: ignore[assignment]
        tenant=linked_tenant
    )
    _set_kill_switch(enabled=False)
    resp = client.post(_revoke_url(share.pk))
    assert resp.status_code == status.HTTP_200_OK
    share.refresh_from_db()
    assert share.revoked_at is not None
