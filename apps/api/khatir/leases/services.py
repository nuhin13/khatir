"""Leases service layer — CRUD + lifecycle (T-003 §2).

Views stay thin (validate → call a service → serialize). The ``landlord`` is
**always** derived server-side from the unit's building owner (never trusted
from the client, T-003 §15). Lifecycle transitions are guarded and audited with
``lease.<verb>`` action strings; activation generates the rent schedule (T-002).

Scoping note: ``create_lease`` resolves the unit through
``Unit.objects.for_user`` so a user can only attach a lease to a unit they own
or manage — a foreign/unknown unit id resolves to **404** (never reveals it
exists, mirroring the building/unit endpoints).
"""

from __future__ import annotations

from decimal import Decimal
from typing import Any, cast

from django.db import transaction

from khatir.accounts.models import User
from khatir.core.audit import audit
from khatir.core.exceptions import ConflictError, NotFoundError, ValidationError
from khatir.properties.models import Unit
from khatir.tenants.models import Tenant

from .enums import LeaseStatus
from .models import Lease
from .scheduling import generate_schedule

# Fields a client may write on a draft lease (landlord/unit/tenant are server-set).
_WRITABLE_FIELDS = ("start_date", "end_date", "rent", "advance", "signed_pdf_ref")


def _snapshot(lease: Lease) -> dict[str, Any]:
    """A JSON-safe before/after snapshot of the audited lease fields."""

    def _coerce(value: Any) -> Any:
        if isinstance(value, Decimal):
            return str(value)
        if hasattr(value, "isoformat"):  # date / datetime
            return value.isoformat()
        return value

    fields = ("unit_id", "tenant_id", "landlord_id", "status", *_WRITABLE_FIELDS)
    return {field: _coerce(getattr(lease, field)) for field in fields}


def create_lease(
    *,
    actor: User,
    unit_id: str,
    tenant_id: str,
    start_date: Any,
    end_date: Any,
    rent: Decimal,
    advance: Decimal | None = None,
) -> Lease:
    """Create a ``draft`` lease and audit it (``lease.create``).

    The unit is resolved through ``Unit.objects.for_user(actor)`` so the caller
    can only lease out a unit they own/manage; an out-of-scope unit raises 404.
    The landlord is taken from that unit's building owner — never the client.
    """
    unit = cast(
        "Unit | None",
        Unit.objects.for_user(actor).filter(pk=unit_id).first(),  # type: ignore[attr-defined]
    )
    if unit is None:
        raise NotFoundError("Unit not found.")

    tenant = cast(
        "Tenant | None", Tenant.objects.filter(pk=tenant_id).first()
    )
    if tenant is None:
        raise NotFoundError("Tenant not found.")

    landlord = unit.building.owner

    lease = cast(
        Lease,
        Lease.objects.create(  # type: ignore[misc]
            unit=unit,
            tenant=tenant,
            landlord=landlord,
            start_date=start_date,
            end_date=end_date,
            rent=rent,
            advance=advance if advance is not None else Decimal("0.00"),
            status=LeaseStatus.DRAFT,
        ),
    )

    audit(
        actor=actor,
        action="lease.create",
        target=lease,
        before=None,
        after=_snapshot(lease),
    )
    return lease


def update_lease(*, actor: User, lease: Lease, **fields: Any) -> Lease:
    """Apply a partial update to a **draft** lease and audit it (``lease.update``).

    Only draft leases are editable — once active/ended/terminated the financial
    terms are locked. Records the before/after of exactly the fields that
    changed; a no-op update changes nothing and audits nothing.
    """
    if lease.status != LeaseStatus.DRAFT:
        raise ValidationError("Only a draft lease can be edited.")

    changes = {k: v for k, v in fields.items() if k in _WRITABLE_FIELDS}
    before = {k: getattr(lease, k) for k in changes}
    after = {k: v for k, v in changes.items() if v != before[k]}

    if not after:
        return lease

    for field, value in after.items():
        setattr(lease, field, value)

    if lease.end_date < lease.start_date:
        raise ValidationError("end_date must be on or after start_date.")

    lease.save(update_fields=[*after.keys(), "updated_at"])

    def _coerce(value: Any) -> Any:
        if isinstance(value, Decimal):
            return str(value)
        if hasattr(value, "isoformat"):
            return value.isoformat()
        return value

    audit(
        actor=actor,
        action="lease.update",
        target=lease,
        before={k: _coerce(before[k]) for k in after},
        after={k: _coerce(v) for k, v in after.items()},
    )
    return lease


def activate_lease(*, actor: User, lease: Lease) -> Lease:
    """Transition a draft lease to ``active`` and generate its rent schedule.

    Guards (T-003 §15): the lease must be a draft, and the unit must have no
    other active lease (no overlapping active lease for the same unit). On
    success the schedule rows are laid out by :func:`generate_schedule` (T-002)
    inside the same transaction, and the transition is audited
    (``lease.activate``).
    """
    if lease.status != LeaseStatus.DRAFT:
        raise ValidationError("Only a draft lease can be activated.")

    overlapping = (
        Lease.objects.filter(unit_id=lease.unit_id, status=LeaseStatus.ACTIVE)
        .exclude(pk=lease.pk)
        .exists()
    )
    if overlapping:
        raise ConflictError("This unit already has an active lease.")

    before = _snapshot(lease)
    with transaction.atomic():
        lease.status = LeaseStatus.ACTIVE
        lease.save(update_fields=["status", "updated_at"])
        generate_schedule(lease)

    audit(
        actor=actor,
        action="lease.activate",
        target=lease,
        before={"status": before["status"]},
        after={"status": lease.status},
    )
    return lease


def terminate_lease(
    *, actor: User, lease: Lease, status: str = LeaseStatus.TERMINATED.value
) -> Lease:
    """Close an **active** lease (``ended`` or ``terminated``) and audit it.

    A draft lease cannot be terminated (it was never active); an already-closed
    lease cannot be re-closed. Audited as ``lease.terminate`` with the chosen
    target status.
    """
    if lease.status != LeaseStatus.ACTIVE:
        raise ValidationError("Only an active lease can be terminated.")

    if status not in {LeaseStatus.ENDED.value, LeaseStatus.TERMINATED.value}:
        raise ValidationError("status must be 'ended' or 'terminated'.")

    before = _snapshot(lease)
    lease.status = status
    lease.save(update_fields=["status", "updated_at"])

    audit(
        actor=actor,
        action="lease.terminate",
        target=lease,
        before={"status": before["status"]},
        after={"status": lease.status},
    )
    return lease
