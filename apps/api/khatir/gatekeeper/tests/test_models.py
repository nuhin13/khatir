"""Tests for ``CaretakerAssignment`` and ``VisitorEntry`` (T-001 §12)."""

from __future__ import annotations

import pytest
from django.db import IntegrityError, transaction

from khatir.accounts.enums import Role
from khatir.gatekeeper.enums import CaretakerAssignmentStatus, VisitorEntryStatus
from khatir.gatekeeper.models import CaretakerAssignment, VisitorEntry
from khatir.properties.tests.factories import UnitFactory

from .factories import (
    CaretakerAssignmentFactory,
    CaretakerUserFactory,
    VisitorEntryFactory,
)

pytestmark = pytest.mark.django_db


# --- CaretakerAssignment -----------------------------------------------------


def test_caretaker_assignment_create() -> None:
    a: CaretakerAssignment = CaretakerAssignmentFactory()  # type: ignore[assignment]
    assert a.pk is not None
    assert a.status == CaretakerAssignmentStatus.ACTIVE
    assert a.caretaker_id is not None
    assert a.building_id is not None
    assert a.assigned_by_id is not None
    assert str(a) != ""


def test_caretaker_assignment_unique_per_building() -> None:
    a: CaretakerAssignment = CaretakerAssignmentFactory()  # type: ignore[assignment]
    with pytest.raises(IntegrityError), transaction.atomic():
        CaretakerAssignmentFactory(caretaker=a.caretaker, building=a.building)


def test_caretaker_assignment_assigned_by_set_null_on_user_delete() -> None:
    a: CaretakerAssignment = CaretakerAssignmentFactory()  # type: ignore[assignment]
    assigner = a.assigned_by
    assert assigner is not None
    assigner.delete()
    a.refresh_from_db()
    assert a.assigned_by_id is None


# --- VisitorEntry ------------------------------------------------------------


def test_visitor_entry_create_defaults() -> None:
    v: VisitorEntry = VisitorEntryFactory()  # type: ignore[assignment]
    v.refresh_from_db()
    assert v.status == VisitorEntryStatus.PENDING
    assert v.unit_id is None
    assert v.logged_by_id is None
    assert v.photo_ref_enc is None
    assert v.created_at is not None
    assert str(v) != ""


def test_visitor_entry_with_unit() -> None:
    unit = UnitFactory()
    v: VisitorEntry = VisitorEntryFactory(building=unit.building, unit=unit)  # type: ignore[assignment]
    v.refresh_from_db()
    assert v.unit_id == unit.pk


def test_visitor_entry_unit_set_null_on_unit_delete() -> None:
    unit = UnitFactory()
    v: VisitorEntry = VisitorEntryFactory(building=unit.building, unit=unit)  # type: ignore[assignment]
    unit.hard_delete()
    v.refresh_from_db()
    assert v.unit_id is None


def test_visitor_entry_photo_ref_encrypted_roundtrip() -> None:
    v: VisitorEntry = VisitorEntryFactory()  # type: ignore[assignment]
    v.set_photo_ref("visitors/2026/abc123.jpg")
    v.save()
    v.refresh_from_db()
    # Stored ciphertext is not the plaintext pointer.
    assert v.photo_ref_enc is not None
    assert b"visitors/2026/abc123.jpg" not in bytes(v.photo_ref_enc)
    # Decrypts back to the original pointer.
    assert v.get_photo_ref() == "visitors/2026/abc123.jpg"


def test_visitor_entry_photo_ref_clear() -> None:
    v: VisitorEntry = VisitorEntryFactory()  # type: ignore[assignment]
    v.set_photo_ref("x/y.jpg")
    v.set_photo_ref(None)
    assert v.photo_ref_enc is None
    assert v.get_photo_ref() is None


def test_visitor_entry_statuses() -> None:
    for s in (
        VisitorEntryStatus.PENDING,
        VisitorEntryStatus.APPROVED,
        VisitorEntryStatus.DENIED,
    ):
        v: VisitorEntry = VisitorEntryFactory(status=s)  # type: ignore[assignment]
        assert v.status == s


def test_caretaker_role_exists() -> None:
    user = CaretakerUserFactory()
    assert user.role == Role.CARETAKER
