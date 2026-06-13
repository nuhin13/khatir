"""API + scoping tests for the manager owner-link endpoints (T-003 §12).

Exercises ``/api/v1/manager/owners`` (request + active-only list) and
``/api/v1/manager/owners/{id}/consent`` (owner accept/decline) through DRF's
``APIClient`` with real authenticated users. Covers the consent lifecycle,
audit on writes, active-link scoping on the list, cross-user 404 isolation,
and the ``b2b_manager_enabled`` feature-flag gate.
"""

from __future__ import annotations

import pytest
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
from khatir.managers.enums import ManagerOwnerLinkStatus
from khatir.managers.models import ManagerOwnerLink

from .factories import ManagerOwnerLinkFactory

pytestmark = pytest.mark.django_db


@pytest.fixture(autouse=True)
def _flag_on() -> None:
    """Enable the B2B manager feature for every test in this module."""
    FeatureFlag.objects.create(
        key="b2b_manager_enabled", scope=FlagScope.GLOBAL, enabled=True
    )


@pytest.fixture
def manager() -> User:
    created: User = UserFactory(  # type: ignore[assignment]
        phone="+8801711111111", name="Manager", role=Role.MANAGER
    )
    return created


@pytest.fixture
def owner() -> User:
    created: User = UserFactory(  # type: ignore[assignment]
        phone="+8801722222222", name="Owner", role=Role.LANDLORD
    )
    return created


@pytest.fixture
def manager_client(manager: User) -> APIClient:
    api = APIClient()
    api.force_authenticate(user=manager)
    return api


@pytest.fixture
def owner_client(owner: User) -> APIClient:
    api = APIClient()
    api.force_authenticate(user=owner)
    return api


# --- request a link ----------------------------------------------------------


def test_request_creates_pending_link_and_audits(
    manager_client: APIClient, manager: User, owner: User
) -> None:
    resp = manager_client.post(
        "/api/v1/manager/owners",
        {"owner_id": owner.pk, "permissions_scope": ["view_reports"]},
        format="json",
    )

    assert resp.status_code == status.HTTP_201_CREATED
    body = resp.json()
    assert body["status"] == ManagerOwnerLinkStatus.PENDING
    assert body["owner"] == owner.pk
    assert body["permissions_scope"] == ["view_reports"]

    link = ManagerOwnerLink.objects.get(pk=body["id"])
    assert link.manager_id == manager.pk
    assert link.is_active is False
    assert AuditEntry.objects.filter(
        action="manager.owner_link.request", target_id=str(link.pk)
    ).exists()


def test_request_rejects_non_landlord_owner(
    manager_client: APIClient,
) -> None:
    tenant = UserFactory(role=Role.TENANT)
    resp = manager_client.post(
        "/api/v1/manager/owners", {"owner_id": tenant.pk}, format="json"
    )
    assert resp.status_code == status.HTTP_400_BAD_REQUEST


def test_request_missing_owner_404(manager_client: APIClient) -> None:
    resp = manager_client.post(
        "/api/v1/manager/owners", {"owner_id": 999999}, format="json"
    )
    assert resp.status_code == status.HTTP_404_NOT_FOUND


def test_duplicate_request_conflicts(
    manager_client: APIClient, manager: User, owner: User
) -> None:
    ManagerOwnerLinkFactory(manager=manager, owner=owner)
    resp = manager_client.post(
        "/api/v1/manager/owners", {"owner_id": owner.pk}, format="json"
    )
    assert resp.status_code == status.HTTP_409_CONFLICT


def test_landlord_cannot_request(owner_client: APIClient, owner: User) -> None:
    other = UserFactory(role=Role.LANDLORD)
    resp = owner_client.post(
        "/api/v1/manager/owners", {"owner_id": other.pk}, format="json"
    )
    assert resp.status_code == status.HTTP_403_FORBIDDEN


# --- owner consent -----------------------------------------------------------


def test_owner_accept_activates_and_records_consent(
    owner_client: APIClient, manager: User, owner: User
) -> None:
    link = ManagerOwnerLinkFactory(
        manager=manager, owner=owner, status=ManagerOwnerLinkStatus.PENDING
    )

    resp = owner_client.post(
        f"/api/v1/manager/owners/{link.pk}/consent",
        {"accept": True},
        format="json",
    )

    assert resp.status_code == status.HTTP_200_OK
    assert resp.json()["status"] == ManagerOwnerLinkStatus.ACTIVE

    link.refresh_from_db()
    assert link.is_active is True
    assert link.consent_record is not None
    assert link.consent_record.consent_type == ConsentType.PDPA_DATA_SHARING
    assert ConsentRecord.objects.filter(user=owner).count() == 1
    assert AuditEntry.objects.filter(
        action="manager.owner_link.accept", target_id=str(link.pk)
    ).exists()


def test_owner_decline_revokes_without_consent(
    owner_client: APIClient, manager: User, owner: User
) -> None:
    link = ManagerOwnerLinkFactory(
        manager=manager, owner=owner, status=ManagerOwnerLinkStatus.PENDING
    )

    resp = owner_client.post(
        f"/api/v1/manager/owners/{link.pk}/consent",
        {"accept": False},
        format="json",
    )

    assert resp.status_code == status.HTTP_200_OK
    link.refresh_from_db()
    assert link.status == ManagerOwnerLinkStatus.REVOKED
    assert link.consent_record is None
    assert not ConsentRecord.objects.filter(user=owner).exists()
    assert AuditEntry.objects.filter(
        action="manager.owner_link.decline", target_id=str(link.pk)
    ).exists()


def test_responding_to_settled_link_conflicts(
    owner_client: APIClient, manager: User, owner: User
) -> None:
    link = ManagerOwnerLinkFactory(
        manager=manager, owner=owner, status=ManagerOwnerLinkStatus.ACTIVE
    )
    resp = owner_client.post(
        f"/api/v1/manager/owners/{link.pk}/consent",
        {"accept": True},
        format="json",
    )
    assert resp.status_code == status.HTTP_409_CONFLICT


def test_owner_cannot_respond_to_others_link_404(
    owner_client: APIClient, manager: User
) -> None:
    other_owner = UserFactory(role=Role.LANDLORD)
    link = ManagerOwnerLinkFactory(
        manager=manager, owner=other_owner, status=ManagerOwnerLinkStatus.PENDING
    )
    resp = owner_client.post(
        f"/api/v1/manager/owners/{link.pk}/consent",
        {"accept": True},
        format="json",
    )
    assert resp.status_code == status.HTTP_404_NOT_FOUND


# --- list scoping ------------------------------------------------------------


def test_list_returns_only_active_links_for_this_manager(
    manager_client: APIClient, manager: User
) -> None:
    active_owner = UserFactory(role=Role.LANDLORD)
    pending_owner = UserFactory(role=Role.LANDLORD)
    other_manager = UserFactory(role=Role.MANAGER)
    other_owner = UserFactory(role=Role.LANDLORD)

    ManagerOwnerLinkFactory(
        manager=manager, owner=active_owner, status=ManagerOwnerLinkStatus.ACTIVE
    )
    ManagerOwnerLinkFactory(
        manager=manager, owner=pending_owner, status=ManagerOwnerLinkStatus.PENDING
    )
    # Another manager's active link must never appear.
    ManagerOwnerLinkFactory(
        manager=other_manager,
        owner=other_owner,
        status=ManagerOwnerLinkStatus.ACTIVE,
    )

    resp = manager_client.get("/api/v1/manager/owners")
    assert resp.status_code == status.HTTP_200_OK
    body = resp.json()
    assert [row["owner"] for row in body] == [active_owner.pk]


# --- feature flag gate -------------------------------------------------------


def test_flag_off_blocks_endpoints(
    manager_client: APIClient, owner: User
) -> None:
    FeatureFlag.objects.filter(key="b2b_manager_enabled").update(enabled=False)
    resp = manager_client.post(
        "/api/v1/manager/owners", {"owner_id": owner.pk}, format="json"
    )
    assert resp.status_code == status.HTTP_403_FORBIDDEN
