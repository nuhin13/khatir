"""Maintenance service layer — CRUD + resolve→auto-expense (T-002 §2).

Views stay thin (validate → call a service → serialize). The unit a request is
attached to is resolved through ``Unit.objects.for_user`` so a caller can only
create/act on requests for units they own or manage — a foreign/unknown unit id
resolves to **404** (never reveals it exists, mirroring the other endpoints).

Resolving a request records the cost and **auto-creates** an ``Expense`` with
``source=request``. The Expense is linked one-to-one back to the request, so a
double-resolve never produces a second expense (idempotent, T-002 §15). The
expense's ``for_user`` ownership flows through the same unit, so the audit trail
and money roll-up stay scoped to the right landlord.
"""

from __future__ import annotations

from datetime import date
from decimal import Decimal
from typing import Any, cast

from django.db import transaction
from django.utils import timezone

from khatir.accounts.models import User
from khatir.core.audit import audit
from khatir.core.exceptions import NotFoundError, ValidationError
from khatir.properties.models import Unit

from .enums import ExpenseSource, MaintenanceStatus
from .models import Expense, MaintenanceRequest

# Fields a client may write when creating a request (unit resolved separately).
_WRITABLE_FIELDS = ("category", "description", "photo_ref", "lease_id")


def _scoped_unit(actor: User, unit_id: Any) -> Unit:
    """Resolve a unit visible to ``actor`` or raise 404."""
    unit = cast(
        "Unit | None",
        Unit.objects.for_user(actor).filter(pk=unit_id).first(),  # type: ignore[attr-defined]
    )
    if unit is None:
        raise NotFoundError("Unit not found.")
    return unit


def create_maintenance_request(
    *,
    actor: User,
    description: str,
    category: str,
    unit_id: Any = None,
    unit: Unit | None = None,
    photo_ref: str = "",
    lease_id: Any | None = None,
) -> MaintenanceRequest:
    """Create an ``open`` maintenance request and audit it (``maintenance.create``).

    The landlord surface passes ``unit_id`` and the unit is resolved through
    ``Unit.objects.for_user(actor)`` so the caller can only report a problem on a
    unit they own/manage; an out-of-scope unit raises 404. A tenant reports on
    *their own* unit, which has already been scoped from their active lease
    (EPIC-19 T-004), so that caller passes a pre-resolved ``unit`` and skips the
    landlord ``for_user`` scope. Exactly one of ``unit_id`` / ``unit`` is given.
    The request always starts ``open`` (status is not client-set).
    """
    if unit is None:
        unit = _scoped_unit(actor, unit_id)

    request = cast(
        MaintenanceRequest,
        MaintenanceRequest.objects.create(  # type: ignore[misc]
            unit=unit,
            lease_id=lease_id,
            category=category,
            description=description,
            photo_ref=photo_ref,
            status=MaintenanceStatus.OPEN,
        ),
    )

    audit(
        actor=actor,
        action="maintenance.create",
        target=request,
        before=None,
        after={
            "unit_id": str(request.unit_id),
            "category": request.category,
            "status": request.status,
        },
    )
    return request


def update_maintenance_request(
    *, actor: User, request: MaintenanceRequest, **fields: Any
) -> MaintenanceRequest:
    """Apply a partial update to an **open** request and audit it.

    Only open requests are editable — once resolved the record (and its linked
    expense) is locked. A no-op update changes nothing and audits nothing.
    """
    if request.status != MaintenanceStatus.OPEN:
        raise ValidationError("Only an open request can be edited.")

    changes = {k: v for k, v in fields.items() if k in _WRITABLE_FIELDS}
    before = {k: getattr(request, k) for k in changes}
    after = {k: v for k, v in changes.items() if v != before[k]}

    if not after:
        return request

    for field, value in after.items():
        setattr(request, field, value)
    request.save(update_fields=[*after.keys(), "updated_at"])

    def _coerce(value: Any) -> Any:
        if hasattr(value, "isoformat"):
            return value.isoformat()
        return value

    audit(
        actor=actor,
        action="maintenance.update",
        target=request,
        before={k: _coerce(before[k]) for k in after},
        after={k: _coerce(v) for k, v in after.items()},
    )
    return request


def resolve_maintenance_request(
    *,
    actor: User,
    request: MaintenanceRequest,
    cost: Decimal,
    note: str = "",
) -> MaintenanceRequest:
    """Resolve a request: mark resolved, record cost, auto-create one Expense.

    Idempotency guard (T-002 §15): a request can only be resolved while
    ``open``; an already-``resolved`` request raises so a double-resolve can
    never create a second expense. The expense is linked one-to-one to the
    request (``source=request``) inside the same transaction, and the resolution
    is audited (``maintenance.resolve``).
    """
    if request.status != MaintenanceStatus.OPEN:
        raise ValidationError("Only an open request can be resolved.")

    resolved_at = timezone.now()
    with transaction.atomic():
        request.status = MaintenanceStatus.RESOLVED
        request.resolved_at = resolved_at
        request.resolution_cost = cost
        request.resolution_note = note
        request.save(
            update_fields=[
                "status",
                "resolved_at",
                "resolution_cost",
                "resolution_note",
                "updated_at",
            ]
        )
        expense = cast(
            Expense,
            Expense.objects.create(  # type: ignore[misc]
                unit_id=request.unit_id,
                request=request,
                category=request.category,
                amount=cost,
                date=cast(date, resolved_at.date()),
                source=ExpenseSource.REQUEST,
                note=note,
            ),
        )

    audit(
        actor=actor,
        action="maintenance.resolve",
        target=request,
        before={"status": MaintenanceStatus.OPEN.value},
        after={
            "status": request.status,
            "resolution_cost": str(cost),
            "expense_id": str(expense.pk),
        },
    )
    return request


# ── Expense CRUD (manual entries) — T-003 ─────────────────────────────────────

# Fields a client may write on a manual expense (unit/source resolved server-side).
_EXPENSE_WRITABLE_FIELDS = ("category", "amount", "date", "note", "receipt_ref")


def _coerce_expense_value(value: Any) -> Any:
    """JSON-safe coercion of an expense field for the audit trail."""
    if isinstance(value, Decimal):
        return str(value)
    if hasattr(value, "isoformat"):  # date / datetime
        return value.isoformat()
    return value


def create_expense(
    *,
    actor: User,
    unit_id: Any,
    amount: Decimal,
    date: Any,
    category: str,
    note: str = "",
    receipt_ref: str = "",
) -> Expense:
    """Create a **manual** expense and audit it (``expense.create``).

    The unit is resolved through ``Unit.objects.for_user(actor)`` so the caller
    can only log an expense against a unit they own/manage; an out-of-scope unit
    raises 404. ``source`` is forced to ``manual`` — auto-expenses come from the
    maintenance resolve action, never this endpoint.
    """
    unit = _scoped_unit(actor, unit_id)

    expense = cast(
        Expense,
        Expense.objects.create(  # type: ignore[misc]
            unit=unit,
            category=category,
            amount=amount,
            date=date,
            source=ExpenseSource.MANUAL,
            note=note,
            receipt_ref=receipt_ref,
        ),
    )

    audit(
        actor=actor,
        action="expense.create",
        target=expense,
        before=None,
        after={
            "unit_id": str(expense.unit_id),
            "category": expense.category,
            "amount": str(expense.amount),
            "date": _coerce_expense_value(expense.date),
            "source": expense.source,
        },
    )
    return expense


def update_expense(*, actor: User, expense: Expense, **fields: Any) -> Expense:
    """Apply a partial update to a **manual** expense and audit it.

    Only manual expenses are editable here — an auto-expense
    (``source=request``) is owned by its maintenance request and is locked. A
    no-op update changes nothing and audits nothing (``expense.update``).
    """
    if expense.source != ExpenseSource.MANUAL:
        raise ValidationError("Only a manual expense can be edited.")

    changes = {k: v for k, v in fields.items() if k in _EXPENSE_WRITABLE_FIELDS}
    before = {k: getattr(expense, k) for k in changes}
    after = {k: v for k, v in changes.items() if v != before[k]}

    if not after:
        return expense

    for field, value in after.items():
        setattr(expense, field, value)
    expense.save(update_fields=[*after.keys(), "updated_at"])

    audit(
        actor=actor,
        action="expense.update",
        target=expense,
        before={k: _coerce_expense_value(before[k]) for k in after},
        after={k: _coerce_expense_value(v) for k, v in after.items()},
    )
    return expense


def delete_expense(*, actor: User, expense: Expense) -> None:
    """Soft-delete a **manual** expense and audit it (``expense.delete``).

    An auto-expense (``source=request``) cannot be deleted directly — it is tied
    to its maintenance request's lifecycle.
    """
    if expense.source != ExpenseSource.MANUAL:
        raise ValidationError("Only a manual expense can be deleted.")

    before = {
        "unit_id": str(expense.unit_id),
        "amount": str(expense.amount),
        "date": _coerce_expense_value(expense.date),
    }
    expense.delete()  # soft-delete (SoftDeleteModel)

    audit(
        actor=actor,
        action="expense.delete",
        target=expense,
        before=before,
        after=None,
    )
