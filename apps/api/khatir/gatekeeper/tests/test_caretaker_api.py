"""API tests for the caretaker-assignment endpoints (T-002 §12).

Exercises ``/api/v1/buildings/{id}/caretakers`` through DRF's ``APIClient``.
Covers the assign/list/revoke happy paths, the owner-only reach + cross-user
**404** (foreign buildings are invisible, never 403, §15), the caretaker-role
guard, ``assigned_by`` server-set, audit writes, idempotent re-assign/re-activate,
and the ``gatekeeper_enabled`` flag gate (§10).
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
from khatir.featureflags.models import FeatureFlag
from khatir.gatekeeper.enums import CaretakerAssignmentStatus
from khatir.gatekeeper.models import CaretakerAssignment
from khatir.properties.models import Building
from khatir.properties.tests.factories import BuildingFactory

from .factories import CaretakerAssignmentFactory, CaretakerUserFactory

pytestmark = pytest.mark.django_db


@pytest.fixture
def owner() -> User:
    created: User = UserFactory(  # type: ignore[assignment]
        phone="+8801712345678", name="Owner", role=Role.LANDLORD
    )
    return created


@pytest.fixture
def building(owner: User) -> Building:
    return BuildingFactory(owner=owner)  # type: ignore[no-any-return]


@pytest.fixture
def caretaker() -> User:
    return CaretakerUserFactory(phone="+8801799999999")  # type: ignore[no-any-return]


@pytest.fixture
def client(owner: User) -> APIClient:
    api = APIClient()
    api.force_authenticate(user=owner)
    return api


def _url(building_id: object) -> str:
    return f"/api/v1/buildings/{building_id}/caretakers"


# ── assign ────────────────────────────────────────────────────────────────────


def test_owner_assigns_caretaker(
    client: APIClient, owner: User, building: Building, caretaker: User
) -> None:
    resp = client.post(
        _url(building.pk), {"caretaker_id": str(caretaker.pk)}, format="json"
    )

    assert resp.status_code == status.HTTP_201_CREATED
    assert resp.data["caretaker_id"] == str(caretaker.pk)
    assert resp.data["building_id"] == str(building.pk)
    assert resp.data["status"] == CaretakerAssignmentStatus.ACTIVE
    # assigned_by is set server-side from request.user.
    assert resp.data["assigned_by_id"] == str(owner.pk)
    row = CaretakerAssignment.objects.get(pk=resp.data["id"])
    assert row.assigned_by_id == owner.pk

    assert AuditEntry.objects.filter(
        action="caretaker.assign", target_id=str(row.pk)
    ).exists()


def test_assign_non_caretaker_user_is_validation_error(
    client: APIClient, building: Building
) -> None:
    not_a_caretaker: User = UserFactory(  # type: ignore[assignment]
        phone="+8801700000000", role=Role.TENANT
    )
    resp = client.post(
        _url(building.pk), {"caretaker_id": str(not_a_caretaker.pk)}, format="json"
    )
    assert resp.status_code == status.HTTP_400_BAD_REQUEST


def test_reassign_active_pair_is_idempotent(
    client: APIClient, building: Building, caretaker: User
) -> None:
    first = client.post(
        _url(building.pk), {"caretaker_id": str(caretaker.pk)}, format="json"
    )
    second = client.post(
        _url(building.pk), {"caretaker_id": str(caretaker.pk)}, format="json"
    )
    assert second.status_code == status.HTTP_201_CREATED
    assert first.data["id"] == second.data["id"]
    assert CaretakerAssignment.objects.filter(
        building=building, caretaker=caretaker
    ).count() == 1


def test_reassign_reactivates_revoked(
    client: APIClient, building: Building, caretaker: User
) -> None:
    revoked = CaretakerAssignmentFactory(
        building=building,
        caretaker=caretaker,
        status=CaretakerAssignmentStatus.REVOKED,
    )
    resp = client.post(
        _url(building.pk), {"caretaker_id": str(caretaker.pk)}, format="json"
    )
    assert resp.status_code == status.HTTP_201_CREATED
    assert resp.data["id"] == str(revoked.pk)
    revoked.refresh_from_db()
    assert revoked.status == CaretakerAssignmentStatus.ACTIVE


# ── list ────────────────────────────────────────────────────────────────────


def test_owner_lists_building_assignments(
    client: APIClient, building: Building, caretaker: User
) -> None:
    CaretakerAssignmentFactory(building=building, caretaker=caretaker)
    CaretakerAssignmentFactory()  # other building — must not appear

    resp = client.get(_url(building.pk))
    assert resp.status_code == status.HTTP_200_OK
    assert len(resp.data) == 1
    assert resp.data[0]["building_id"] == str(building.pk)


# ── revoke ────────────────────────────────────────────────────────────────────


def test_owner_revokes_assignment(
    client: APIClient, owner: User, building: Building, caretaker: User
) -> None:
    assignment = CaretakerAssignmentFactory(building=building, caretaker=caretaker)
    resp = client.delete(f"{_url(building.pk)}/{assignment.pk}")
    assert resp.status_code == status.HTTP_204_NO_CONTENT
    assignment.refresh_from_db()
    assert assignment.status == CaretakerAssignmentStatus.REVOKED
    assert AuditEntry.objects.filter(
        action="caretaker.revoke", target_id=str(assignment.pk)
    ).exists()


# ── scoping / permissions ─────────────────────────────────────────────────────


def test_assign_to_foreign_building_is_404(
    client: APIClient, caretaker: User
) -> None:
    foreign = BuildingFactory()  # owned by someone else
    resp = client.post(
        _url(foreign.pk), {"caretaker_id": str(caretaker.pk)}, format="json"
    )
    # Foreign building is invisible — 404, never 403 (no existence leak).
    assert resp.status_code == status.HTTP_404_NOT_FOUND
    assert not CaretakerAssignment.objects.filter(building=foreign).exists()


def test_caretaker_cannot_reach_endpoint(building: Building, caretaker: User) -> None:
    api = APIClient()
    api.force_authenticate(user=caretaker)
    resp = api.get(_url(building.pk))
    assert resp.status_code == status.HTTP_403_FORBIDDEN


def test_anonymous_is_rejected(building: Building) -> None:
    resp = APIClient().get(_url(building.pk))
    assert resp.status_code in (
        status.HTTP_401_UNAUTHORIZED,
        status.HTTP_403_FORBIDDEN,
    )


# ── feature flag ──────────────────────────────────────────────────────────────


def test_flag_off_returns_feature_disabled(
    client: APIClient, building: Building, caretaker: User
) -> None:
    FeatureFlag.objects.create(
        key="gatekeeper_enabled", scope=FlagScope.GLOBAL, enabled=False
    )
    resp = client.post(
        _url(building.pk), {"caretaker_id": str(caretaker.pk)}, format="json"
    )
    assert resp.status_code == status.HTTP_403_FORBIDDEN
    assert resp.data["error"]["code"] == "feature_disabled"
