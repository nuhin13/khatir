"""Tests for the tenant-initiated share endpoint (EPIC-24.T-002 §12).

Exercises ``POST /api/v1/me/history-shares``:

* a tenant (and only a tenant) can create a share;
* a ConsentRecord is logged per share (pdpa_data_sharing) and linked;
* FACTUAL stats are snapshotted and no subjective field is returned;
* the share is expirable and the past-expiry guard rejects bad input;
* the ``history_flags_feature`` kill-switch gates the endpoint;
* there is no landlord-initiated variant (landlords are forbidden).
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
from khatir.compliance.enums import ConsentType
from khatir.compliance.models import ConsentRecord
from khatir.core.models import AuditEntry
from khatir.featureflags.enums import FlagScope
from khatir.featureflags.models import FeatureFlag
from khatir.historyshare.flags import HISTORY_FLAGS_FEATURE
from khatir.historyshare.models import HistoryShare
from khatir.tenants.tests.factories import TenantFactory

pytestmark = pytest.mark.django_db

URL = "/api/v1/me/history-shares"


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


def _set_kill_switch(*, enabled: bool) -> None:
    FeatureFlag.objects.update_or_create(
        key=HISTORY_FLAGS_FEATURE,
        defaults={"scope": FlagScope.GLOBAL, "enabled": enabled},
    )


# --- happy path --------------------------------------------------------------


def test_tenant_creates_share(
    client: APIClient, landlord: User, linked_tenant: object
) -> None:
    resp = client.post(URL, {"recipient_landlord": landlord.pk}, format="json")

    assert resp.status_code == status.HTTP_201_CREATED
    body = resp.json()
    assert body["recipient_landlord"] == landlord.pk
    assert body["tenant"] == linked_tenant.pk  # type: ignore[attr-defined]
    assert body["revoked_at"] is None

    share = HistoryShare.objects.get(pk=body["id"])
    assert share.tenant_id == linked_tenant.pk  # type: ignore[attr-defined]
    assert share.recipient_landlord_id == landlord.pk


def test_share_logs_per_share_consent(
    client: APIClient, landlord: User, linked_tenant: object
) -> None:
    client.post(URL, {"recipient_landlord": landlord.pk}, format="json")

    consent = ConsentRecord.objects.get(consent_type=ConsentType.PDPA_DATA_SHARING)
    share = HistoryShare.objects.get()
    assert share.consent_record_id == consent.pk
    assert consent.revoked_at is None


def test_share_snapshots_factual_stats_no_subjective(
    client: APIClient, landlord: User, linked_tenant: object
) -> None:
    body = client.post(
        URL, {"recipient_landlord": landlord.pk}, format="json"
    ).json()

    stats = body["factual_stats"]
    assert set(stats) == {
        "on_time_payment_count",
        "total_payments",
        "lease_completed",
    }
    # No subjective field leaks through the response anywhere.
    forbidden = {"rating", "score", "opinion", "review", "comment", "stars"}
    assert set(body).isdisjoint(forbidden)
    assert set(stats).isdisjoint(forbidden)


def test_share_is_audited(
    client: APIClient, landlord: User, linked_tenant: object
) -> None:
    client.post(URL, {"recipient_landlord": landlord.pk}, format="json")
    assert AuditEntry.objects.filter(action="history_share.create").exists()


def test_share_accepts_future_expiry(
    client: APIClient, landlord: User, linked_tenant: object
) -> None:
    future = timezone.now() + datetime.timedelta(days=30)
    resp = client.post(
        URL,
        {"recipient_landlord": landlord.pk, "expires_at": future.isoformat()},
        format="json",
    )
    assert resp.status_code == status.HTTP_201_CREATED
    share = HistoryShare.objects.get()
    assert share.expires_at is not None
    # Consent expiry mirrors the share expiry.
    assert share.consent_record.expires_at is not None


# --- guards ------------------------------------------------------------------


def test_past_expiry_rejected(
    client: APIClient, landlord: User, linked_tenant: object
) -> None:
    past = timezone.now() - datetime.timedelta(days=1)
    resp = client.post(
        URL,
        {"recipient_landlord": landlord.pk, "expires_at": past.isoformat()},
        format="json",
    )
    assert resp.status_code == status.HTTP_400_BAD_REQUEST
    assert HistoryShare.objects.count() == 0
    # Atomic: a rejected share leaves no orphan consent record.
    assert ConsentRecord.objects.count() == 0


def test_tenant_without_profile_rejected(
    client: APIClient, landlord: User
) -> None:
    # No linked_tenant fixture: the caller has no tenant identity.
    resp = client.post(URL, {"recipient_landlord": landlord.pk}, format="json")
    assert resp.status_code == status.HTTP_400_BAD_REQUEST
    assert HistoryShare.objects.count() == 0


def test_recipient_must_be_landlord(
    client: APIClient, tenant_user: User, linked_tenant: object
) -> None:
    other_tenant: User = UserFactory(  # type: ignore[assignment]
        phone="+8801700000003", role=Role.TENANT
    )
    resp = client.post(
        URL, {"recipient_landlord": other_tenant.pk}, format="json"
    )
    assert resp.status_code == status.HTTP_400_BAD_REQUEST
    assert HistoryShare.objects.count() == 0


def test_landlord_cannot_initiate(landlord: User) -> None:
    """No landlord-initiated variant exists — landlords are forbidden."""
    api = APIClient()
    api.force_authenticate(user=landlord)
    resp = api.post(URL, {"recipient_landlord": landlord.pk}, format="json")
    assert resp.status_code in (
        status.HTTP_401_UNAUTHORIZED,
        status.HTTP_403_FORBIDDEN,
    )


def test_requires_auth(landlord: User) -> None:
    resp = APIClient().post(URL, {"recipient_landlord": landlord.pk}, format="json")
    assert resp.status_code in (
        status.HTTP_401_UNAUTHORIZED,
        status.HTTP_403_FORBIDDEN,
    )


def test_kill_switch_blocks_share(
    client: APIClient, landlord: User, linked_tenant: object
) -> None:
    _set_kill_switch(enabled=False)
    resp = client.post(URL, {"recipient_landlord": landlord.pk}, format="json")
    assert resp.status_code == status.HTTP_403_FORBIDDEN
    assert resp.json()["error"]["code"] == "feature_disabled"
    assert HistoryShare.objects.count() == 0


def test_kill_switch_on_allows_share(
    client: APIClient, landlord: User, linked_tenant: object
) -> None:
    _set_kill_switch(enabled=True)
    resp = client.post(URL, {"recipient_landlord": landlord.pk}, format="json")
    assert resp.status_code == status.HTTP_201_CREATED
