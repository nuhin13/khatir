"""Row-level scoping tests for the gatekeeper domain (T-001 §12).

Caretakers see only the buildings they are *actively* assigned to (and the
visitor entries logged there); owners/managers see their own buildings; other
roles and anonymous users see nothing.
"""

from __future__ import annotations

import pytest

from khatir.accounts.tests.factories import UserFactory
from khatir.gatekeeper.enums import CaretakerAssignmentStatus
from khatir.gatekeeper.models import CaretakerAssignment, VisitorEntry
from khatir.properties.tests.factories import BuildingFactory

from .factories import (
    CaretakerAssignmentFactory,
    CaretakerUserFactory,
    VisitorEntryFactory,
)

pytestmark = pytest.mark.django_db


class _Anon:
    is_authenticated = False
    role = None


def test_caretaker_sees_only_assigned_buildings_assignments() -> None:
    caretaker = CaretakerUserFactory()
    mine = CaretakerAssignmentFactory(caretaker=caretaker)
    other = CaretakerAssignmentFactory()  # different caretaker + building

    visible = list(CaretakerAssignment.objects.for_user(caretaker))
    assert mine in visible
    assert other not in visible


def test_caretaker_sees_visitor_entries_only_for_active_buildings() -> None:
    caretaker = CaretakerUserFactory()
    active = CaretakerAssignmentFactory(caretaker=caretaker)
    revoked = CaretakerAssignmentFactory(
        caretaker=caretaker, status=CaretakerAssignmentStatus.REVOKED
    )
    unassigned_building = BuildingFactory()

    in_scope = VisitorEntryFactory(building=active.building)
    out_revoked = VisitorEntryFactory(building=revoked.building)
    out_unassigned = VisitorEntryFactory(building=unassigned_building)

    visible = list(VisitorEntry.objects.for_user(caretaker))
    assert in_scope in visible
    assert out_revoked not in visible
    assert out_unassigned not in visible


def test_owner_sees_assignments_and_entries_for_owned_buildings() -> None:
    owner = UserFactory()  # default role landlord
    building = BuildingFactory(owner=owner)
    assignment = CaretakerAssignmentFactory(building=building)
    entry = VisitorEntryFactory(building=building)

    other_building = BuildingFactory()
    CaretakerAssignmentFactory(building=other_building)
    VisitorEntryFactory(building=other_building)

    assert assignment in list(CaretakerAssignment.objects.for_user(owner))
    assert entry in list(VisitorEntry.objects.for_user(owner))
    assert CaretakerAssignment.objects.for_user(owner).count() == 1
    assert VisitorEntry.objects.for_user(owner).count() == 1


def test_anonymous_and_unrelated_user_see_nothing() -> None:
    CaretakerAssignmentFactory()
    VisitorEntryFactory()
    stranger = UserFactory()  # landlord owning no buildings here

    assert CaretakerAssignment.objects.for_user(_Anon()).count() == 0
    assert VisitorEntry.objects.for_user(_Anon()).count() == 0
    assert CaretakerAssignment.objects.for_user(stranger).count() == 0
    assert VisitorEntry.objects.for_user(stranger).count() == 0
