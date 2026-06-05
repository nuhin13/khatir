"""Caretaker-assignment service layer — assign / revoke (T-002 §2).

Views stay thin (validate → call a service → serialize). The building is always
resolved from the scoped URL and ``assigned_by`` is set from ``request.user`` —
never trusted from the client (T-002 §14). Every mutation writes an
:class:`~khatir.core.models.AuditEntry` via ``core.audit.audit`` with a
``caretaker.verb`` action string (``enums.md`` — open set).

Assigning is idempotent against the ``uniq_caretaker_building`` constraint: a
revoked assignment for the same caretaker+building is re-activated rather than
duplicated, and re-assigning an already-active pair is a no-op (still returns the
row, audits nothing). Only Users whose **role is caretaker** may be assigned.
"""

from __future__ import annotations

from typing import Any

from django.db import transaction

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.core.audit import audit
from khatir.core.exceptions import ValidationError

from .enums import CaretakerAssignmentStatus
from .models import CaretakerAssignment


def _snapshot(assignment: CaretakerAssignment) -> dict[str, Any]:
    """A JSON-safe snapshot of the audited assignment fields."""
    return {
        "caretaker_id": str(assignment.caretaker_id),
        "building_id": str(assignment.building_id),
        "status": assignment.status,
    }


def _resolve_caretaker(caretaker_id: str) -> User:
    """Resolve ``caretaker_id`` to a caretaker-role User or raise ``ValidationError``.

    A non-existent id or a User whose role is not ``caretaker`` is a client
    error (the building is the addressable resource, the caretaker is body data),
    so this surfaces as ``validation_error`` rather than a 404 on the building.
    """
    user = User.objects.filter(pk=caretaker_id).first()
    if user is None or user.role != Role.CARETAKER:
        raise ValidationError(
            "caretaker_id must reference an existing caretaker user.",
            details={"caretaker_id": "No caretaker user with this id."},
        )
    return user


@transaction.atomic
def assign_caretaker(
    *, actor: User, building: Any, caretaker_id: str
) -> CaretakerAssignment:
    """Assign the caretaker identified by ``caretaker_id`` to ``building``.

    Creates a new active assignment, or re-activates an existing (revoked) one
    for the same caretaker+building so the unique constraint is never violated.
    Re-assigning an already-active pair returns the row unchanged (no audit).
    Audited ``caretaker.assign`` on a real state change; ``assigned_by`` is the
    acting owner/manager.
    """
    caretaker = _resolve_caretaker(caretaker_id)

    existing = CaretakerAssignment.objects.filter(
        caretaker=caretaker, building=building
    ).first()

    if existing is not None:
        if existing.status == CaretakerAssignmentStatus.ACTIVE:
            return existing  # already active — idempotent no-op
        before = _snapshot(existing)
        existing.status = CaretakerAssignmentStatus.ACTIVE
        existing.assigned_by = actor
        existing.save(update_fields=["status", "assigned_by", "updated_at"])
        audit(
            actor=actor,
            action="caretaker.assign",
            target=existing,
            before=before,
            after=_snapshot(existing),
        )
        return existing

    assignment = CaretakerAssignment.objects.create(
        caretaker=caretaker,
        building=building,
        assigned_by=actor,
        status=CaretakerAssignmentStatus.ACTIVE,
    )
    audit(
        actor=actor,
        action="caretaker.assign",
        target=assignment,
        before=None,
        after=_snapshot(assignment),
    )
    return assignment


@transaction.atomic
def revoke_caretaker(
    *, actor: User, assignment: CaretakerAssignment
) -> CaretakerAssignment:
    """Revoke ``assignment`` (soft state flip) and audit it (``caretaker.revoke``).

    Revoking an already-revoked assignment is a no-op (audits nothing). A revoked
    assignment no longer grants the caretaker visitor-entry visibility (see
    ``managers._active_assigned_building_ids``).
    """
    if assignment.status == CaretakerAssignmentStatus.REVOKED:
        return assignment

    before = _snapshot(assignment)
    assignment.status = CaretakerAssignmentStatus.REVOKED
    assignment.save(update_fields=["status", "updated_at"])
    audit(
        actor=actor,
        action="caretaker.revoke",
        target=assignment,
        before=before,
        after=_snapshot(assignment),
    )
    return assignment
