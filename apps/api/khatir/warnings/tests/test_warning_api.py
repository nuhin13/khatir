"""API tests for the warning issue + list endpoints (T-002 §12).

Drives ``/api/v1/leases/{id}/warnings`` through DRF's ``APIClient``. Covers:
issuing a warning (201, landlord's own lease/tenant, audited), listing only the
caller's own warnings (never cross-landlord), the ``warnings_feature``
kill-switch (live by default, 403 ``feature_disabled`` when off), and that a
foreign lease resolves to 404 (we never reveal it exists).
"""

from __future__ import annotations

import pytest
from rest_framework import status
from rest_framework.test import APIClient

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.core.models import AuditEntry
from khatir.featureflags.enums import FlagScope
from khatir.featureflags.tests.factories import FeatureFlagFactory
from khatir.leases.tests.factories import LeaseFactory
from khatir.warnings.enums import WarningType
from khatir.warnings.models import Warning

pytestmark = pytest.mark.django_db


def _path(lease_id: int) -> str:
    return f"/api/v1/leases/{lease_id}/warnings"


@pytest.fixture
def landlord() -> User:
    created: User = UserFactory(  # type: ignore[assignment]
        phone="+8801712345678", name="Landlord A", role=Role.LANDLORD
    )
    return created


@pytest.fixture
def client(landlord: User) -> APIClient:
    api = APIClient()
    api.force_authenticate(user=landlord)
    return api


def test_issue(client: APIClient, landlord: User) -> None:
    lease = LeaseFactory(landlord=landlord)
    resp = client.post(
        _path(lease.pk),
        {"warning_type": WarningType.LATE_RENT, "reason": "Rent overdue 14 days"},
        format="json",
    )
    assert resp.status_code == status.HTTP_201_CREATED
    body = resp.json()
    assert body["warning_type"] == WarningType.LATE_RENT
    assert body["reason"] == "Rent overdue 14 days"
    # Landlord + tenant are derived server-side from the lease, never the client.
    assert body["landlord"] == str(landlord.pk)
    assert body["tenant"] == str(lease.tenant_id)
    assert body["lease"] == str(lease.pk)

    warning = Warning.objects.get(pk=body["id"])
    assert warning.landlord_id == landlord.pk
    assert warning.tenant_id == lease.tenant_id
    # The issue is audited.
    assert AuditEntry.objects.filter(
        action="warning.issue", target_id=str(warning.pk)
    ).exists()


def test_issue_defaults_to_other_type(client: APIClient, landlord: User) -> None:
    lease = LeaseFactory(landlord=landlord)
    resp = client.post(_path(lease.pk), {"reason": "Unspecified"}, format="json")
    assert resp.status_code == status.HTTP_201_CREATED
    assert resp.json()["warning_type"] == WarningType.OTHER


def test_issue_blank_reason_rejected(client: APIClient, landlord: User) -> None:
    lease = LeaseFactory(landlord=landlord)
    resp = client.post(_path(lease.pk), {"reason": ""}, format="json")
    assert resp.status_code == status.HTTP_400_BAD_REQUEST


def test_list_own_only(client: APIClient, landlord: User) -> None:
    """The list returns only the caller's own warnings on the lease."""
    lease = LeaseFactory(landlord=landlord)
    client.post(_path(lease.pk), {"reason": "First"}, format="json")
    client.post(_path(lease.pk), {"reason": "Second"}, format="json")

    # A second landlord with their own warning on a different lease.
    other = UserFactory(phone="+8801722222222", role=Role.LANDLORD)
    other_lease = LeaseFactory(landlord=other)
    Warning.objects.create(
        lease=other_lease,
        tenant_id=other_lease.tenant_id,
        landlord=other,
        reason="Other landlord's warning",
    )

    resp = client.get(_path(lease.pk))
    assert resp.status_code == status.HTTP_200_OK
    reasons = {w["reason"] for w in resp.json()}
    assert reasons == {"First", "Second"}


def test_killswitch_off(client: APIClient, landlord: User) -> None:
    """When ``warnings_feature`` is off, both verbs return feature_disabled 403."""
    FeatureFlagFactory(
        key="warnings_feature", scope=FlagScope.GLOBAL, enabled=False
    )
    lease = LeaseFactory(landlord=landlord)

    get_resp = client.get(_path(lease.pk))
    assert get_resp.status_code == status.HTTP_403_FORBIDDEN
    assert get_resp.json()["error"]["code"] == "feature_disabled"

    post_resp = client.post(_path(lease.pk), {"reason": "x"}, format="json")
    assert post_resp.status_code == status.HTTP_403_FORBIDDEN
    assert post_resp.json()["error"]["code"] == "feature_disabled"
    # Nothing was written.
    assert not Warning.objects.filter(lease=lease).exists()


def test_killswitch_on_by_default(client: APIClient, landlord: User) -> None:
    """With the switch seeded live, the feature works."""
    FeatureFlagFactory(
        key="warnings_feature", scope=FlagScope.GLOBAL, enabled=True
    )
    lease = LeaseFactory(landlord=landlord)
    resp = client.post(_path(lease.pk), {"reason": "Live"}, format="json")
    assert resp.status_code == status.HTTP_201_CREATED


def test_cross_landlord_404(client: APIClient, landlord: User) -> None:
    """A foreign lease is invisible — both verbs resolve to 404, never a leak."""
    other = UserFactory(phone="+8801733333333", role=Role.LANDLORD)
    foreign_lease = LeaseFactory(landlord=other)

    get_resp = client.get(_path(foreign_lease.pk))
    assert get_resp.status_code == status.HTTP_404_NOT_FOUND

    post_resp = client.post(
        _path(foreign_lease.pk), {"reason": "x"}, format="json"
    )
    assert post_resp.status_code == status.HTTP_404_NOT_FOUND
    assert not Warning.objects.filter(lease=foreign_lease).exists()


def test_requires_auth() -> None:
    lease = LeaseFactory()
    resp = APIClient().get(_path(lease.pk))
    assert resp.status_code in (
        status.HTTP_401_UNAUTHORIZED,
        status.HTTP_403_FORBIDDEN,
    )
