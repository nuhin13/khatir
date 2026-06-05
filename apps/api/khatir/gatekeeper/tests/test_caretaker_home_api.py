"""API tests for the caretaker home + visitor review endpoints (T-003 §12).

Exercises ``/api/v1/caretaker/home``, ``/api/v1/caretaker/visitors`` and
``/api/v1/caretaker/visitors/{id}/review`` through DRF's ``APIClient``. Covers the
happy paths, the active-assignment scoping (a caretaker sees only their assigned
buildings' visitors, foreign entries are **404**), the caretaker-role reach gate,
the already-reviewed conflict, audit writes, and the ``gatekeeper_enabled`` flag
gate (§10).
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
from khatir.gatekeeper.enums import (
    CaretakerAssignmentStatus,
    VisitorEntryStatus,
)
from khatir.gatekeeper.models import VisitorEntry
from khatir.properties.models import Building

from .factories import (
    CaretakerAssignmentFactory,
    CaretakerUserFactory,
    VisitorEntryFactory,
)

pytestmark = pytest.mark.django_db

HOME_URL = "/api/v1/caretaker/home"
QUEUE_URL = "/api/v1/caretaker/visitors"


def _review_url(entry_id: object) -> str:
    return f"/api/v1/caretaker/visitors/{entry_id}/review"


@pytest.fixture
def caretaker() -> User:
    return CaretakerUserFactory(phone="+8801799999999")  # type: ignore[no-any-return]


@pytest.fixture
def assigned_building(caretaker: User) -> Building:
    """A building the caretaker is *actively* assigned to."""
    assignment = CaretakerAssignmentFactory(
        caretaker=caretaker, status=CaretakerAssignmentStatus.ACTIVE
    )
    return assignment.building  # type: ignore[no-any-return]


@pytest.fixture
def client(caretaker: User) -> APIClient:
    api = APIClient()
    api.force_authenticate(user=caretaker)
    return api


# ── home ────────────────────────────────────────────────────────────────────


def test_home_summarises_todays_activity(
    client: APIClient, assigned_building: Building
) -> None:
    VisitorEntryFactory(building=assigned_building, status=VisitorEntryStatus.PENDING)
    VisitorEntryFactory(building=assigned_building, status=VisitorEntryStatus.APPROVED)
    VisitorEntryFactory(building=assigned_building, status=VisitorEntryStatus.DENIED)
    # Foreign building (not assigned) — must not be counted.
    VisitorEntryFactory(status=VisitorEntryStatus.PENDING)

    resp = client.get(HOME_URL)

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data["counts"]["total"] == 3
    assert resp.data["counts"]["pending"] == 1
    assert resp.data["counts"]["approved"] == 1
    assert resp.data["counts"]["denied"] == 1
    assert len(resp.data["recent"]) == 3
    # Photo pointer is never exposed.
    assert "photo_ref" not in resp.data["recent"][0]
    assert "photo_ref_enc" not in resp.data["recent"][0]


def test_home_caretaker_role_required(assigned_building: Building) -> None:
    landlord: User = UserFactory(  # type: ignore[assignment]
        phone="+8801710000000", role=Role.LANDLORD
    )
    api = APIClient()
    api.force_authenticate(user=landlord)
    assert api.get(HOME_URL).status_code == status.HTTP_403_FORBIDDEN


def test_home_anonymous_rejected() -> None:
    resp = APIClient().get(HOME_URL)
    assert resp.status_code in (
        status.HTTP_401_UNAUTHORIZED,
        status.HTTP_403_FORBIDDEN,
    )


# ── visitor queue ─────────────────────────────────────────────────────────────


def test_queue_lists_pending_for_assigned_buildings_fifo(
    client: APIClient, assigned_building: Building
) -> None:
    first = VisitorEntryFactory(
        building=assigned_building, status=VisitorEntryStatus.PENDING
    )
    second = VisitorEntryFactory(
        building=assigned_building, status=VisitorEntryStatus.PENDING
    )
    # Non-pending and foreign entries must not appear.
    VisitorEntryFactory(
        building=assigned_building, status=VisitorEntryStatus.APPROVED
    )
    VisitorEntryFactory(status=VisitorEntryStatus.PENDING)

    resp = client.get(QUEUE_URL)

    assert resp.status_code == status.HTTP_200_OK
    ids = [row["id"] for row in resp.data]
    assert ids == [str(first.pk), str(second.pk)]  # oldest first


def test_queue_excludes_revoked_assignment_buildings(caretaker: User) -> None:
    revoked = CaretakerAssignmentFactory(
        caretaker=caretaker, status=CaretakerAssignmentStatus.REVOKED
    )
    VisitorEntryFactory(
        building=revoked.building, status=VisitorEntryStatus.PENDING
    )
    api = APIClient()
    api.force_authenticate(user=caretaker)

    resp = api.get(QUEUE_URL)
    assert resp.status_code == status.HTTP_200_OK
    assert resp.data == []


# ── review ────────────────────────────────────────────────────────────────────


def test_review_approves_entry_and_audits(
    client: APIClient, caretaker: User, assigned_building: Building
) -> None:
    entry = VisitorEntryFactory(
        building=assigned_building, status=VisitorEntryStatus.PENDING
    )
    resp = client.post(
        _review_url(entry.pk), {"decision": VisitorEntryStatus.APPROVED}, format="json"
    )

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data["status"] == VisitorEntryStatus.APPROVED
    entry.refresh_from_db()
    assert entry.status == VisitorEntryStatus.APPROVED
    # logged_by is set server-side from the acting caretaker.
    assert entry.logged_by_id == caretaker.pk
    assert AuditEntry.objects.filter(
        action="visitor.review", target_id=str(entry.pk)
    ).exists()


def test_review_denies_entry(
    client: APIClient, assigned_building: Building
) -> None:
    entry = VisitorEntryFactory(
        building=assigned_building, status=VisitorEntryStatus.PENDING
    )
    resp = client.post(
        _review_url(entry.pk), {"decision": VisitorEntryStatus.DENIED}, format="json"
    )
    assert resp.status_code == status.HTTP_200_OK
    entry.refresh_from_db()
    assert entry.status == VisitorEntryStatus.DENIED


def test_review_already_reviewed_is_conflict(
    client: APIClient, assigned_building: Building
) -> None:
    entry = VisitorEntryFactory(
        building=assigned_building, status=VisitorEntryStatus.APPROVED
    )
    resp = client.post(
        _review_url(entry.pk), {"decision": VisitorEntryStatus.DENIED}, format="json"
    )
    assert resp.status_code == status.HTTP_409_CONFLICT
    entry.refresh_from_db()
    assert entry.status == VisitorEntryStatus.APPROVED  # unchanged


def test_review_invalid_decision_is_validation_error(
    client: APIClient, assigned_building: Building
) -> None:
    entry = VisitorEntryFactory(
        building=assigned_building, status=VisitorEntryStatus.PENDING
    )
    resp = client.post(
        _review_url(entry.pk), {"decision": "maybe"}, format="json"
    )
    assert resp.status_code == status.HTTP_400_BAD_REQUEST


def test_review_foreign_entry_is_404(client: APIClient) -> None:
    foreign = VisitorEntryFactory(status=VisitorEntryStatus.PENDING)
    resp = client.post(
        _review_url(foreign.pk),
        {"decision": VisitorEntryStatus.APPROVED},
        format="json",
    )
    # Entry at a non-assigned building is invisible — 404, never 403.
    assert resp.status_code == status.HTTP_404_NOT_FOUND
    foreign.refresh_from_db()
    assert foreign.status == VisitorEntryStatus.PENDING  # untouched


def test_review_revoked_assignment_entry_is_404(caretaker: User) -> None:
    revoked = CaretakerAssignmentFactory(
        caretaker=caretaker, status=CaretakerAssignmentStatus.REVOKED
    )
    entry = VisitorEntryFactory(
        building=revoked.building, status=VisitorEntryStatus.PENDING
    )
    api = APIClient()
    api.force_authenticate(user=caretaker)
    resp = api.post(
        _review_url(entry.pk),
        {"decision": VisitorEntryStatus.APPROVED},
        format="json",
    )
    assert resp.status_code == status.HTTP_404_NOT_FOUND


# ── feature flag ──────────────────────────────────────────────────────────────


def test_flag_off_returns_feature_disabled(
    client: APIClient, assigned_building: Building
) -> None:
    FeatureFlag.objects.create(
        key="gatekeeper_enabled", scope=FlagScope.GLOBAL, enabled=False
    )
    resp = client.get(HOME_URL)
    assert resp.status_code == status.HTTP_403_FORBIDDEN
    assert resp.data["error"]["code"] == "feature_disabled"


def test_review_persists_only_one_state(
    client: APIClient, assigned_building: Building
) -> None:
    """A reviewed entry stays terminal; the row count and others are untouched."""
    target = VisitorEntryFactory(
        building=assigned_building, status=VisitorEntryStatus.PENDING
    )
    other = VisitorEntryFactory(
        building=assigned_building, status=VisitorEntryStatus.PENDING
    )
    client.post(
        _review_url(target.pk),
        {"decision": VisitorEntryStatus.APPROVED},
        format="json",
    )
    other.refresh_from_db()
    assert other.status == VisitorEntryStatus.PENDING
    assert VisitorEntry.objects.count() == 2
