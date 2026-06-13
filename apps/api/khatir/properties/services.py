"""Buildings service layer — business logic for create/update/delete (T-003 §2).

Views stay thin (validate → call a service → serialize). The owner is **always**
set from ``request.user`` on create (never trusted from the client, T-003 §15).
Every mutation writes an :class:`~khatir.core.models.AuditEntry` via
``core.audit.audit`` (``domain.verb`` action strings).
"""

from __future__ import annotations

from decimal import Decimal
from typing import Any, cast

from django.db import transaction
from django.db.models import QuerySet

from khatir.accounts.models import User
from khatir.core.audit import audit

from .models import Building, Unit
from .unit_generation import generate_unit_labels

# Fields a client may write on a building (owner is server-set, never here).
_WRITABLE_FIELDS = ("name", "area", "address", "lat", "lng")

# Fields a client may write on a unit (building is set from the URL, never here).
_UNIT_WRITABLE_FIELDS = (
    "label",
    "type",
    "rent",
    "amenities",
    "status",
    "available_from",
)


def _snapshot(building: Building) -> dict[str, Any]:
    """A JSON-safe before/after snapshot of the writable building fields."""

    def _coerce(value: Any) -> Any:
        return str(value) if isinstance(value, Decimal) else value

    return {field: _coerce(getattr(building, field)) for field in _WRITABLE_FIELDS}


def create_building(*, owner: User, **fields: Any) -> Building:
    """Create a building owned by ``owner`` and audit it (``building.create``).

    ``owner`` is the authenticated user — the client never supplies it. Only the
    writable fields are persisted; everything else is ignored.
    """
    data = {k: v for k, v in fields.items() if k in _WRITABLE_FIELDS}
    building = cast(
        Building,
        Building.objects.create(owner=owner, **data),  # type: ignore[misc]
    )

    audit(
        actor=owner,
        action="building.create",
        target=building,
        before=None,
        after=_snapshot(building),
    )
    return building


def update_building(*, actor: User, building: Building, **fields: Any) -> Building:
    """Apply a partial update to ``building`` and audit the change.

    Records the before/after of exactly the fields that changed
    (``building.update``). A no-op update changes nothing and audits nothing.
    """
    changes = {k: v for k, v in fields.items() if k in _WRITABLE_FIELDS}
    before_full = _snapshot(building)
    before = {k: getattr(building, k) for k in changes}
    after = {k: v for k, v in changes.items() if v != before[k]}

    if not after:
        return building

    for field, value in after.items():
        setattr(building, field, value)
    building.save(update_fields=[*after.keys(), "updated_at"])

    after_full = _snapshot(building)
    audit(
        actor=actor,
        action="building.update",
        target=building,
        before={k: before_full[k] for k in after},
        after={k: after_full[k] for k in after},
    )
    return building


def delete_building(*, actor: User, building: Building) -> None:
    """Soft-delete ``building`` and audit it (``building.delete``)."""
    before = _snapshot(building)
    building.delete()  # soft delete (SoftDeleteModel)

    audit(
        actor=actor,
        action="building.delete",
        target=building,
        before=before,
        after=None,
    )


def _unit_snapshot(unit: Unit) -> dict[str, Any]:
    """A JSON-safe before/after snapshot of the writable unit fields."""

    def _coerce(value: Any) -> Any:
        if isinstance(value, Decimal):
            return str(value)
        if hasattr(value, "isoformat"):  # date / datetime
            return value.isoformat()
        return value

    return {
        field: _coerce(getattr(unit, field)) for field in _UNIT_WRITABLE_FIELDS
    }


def create_unit(*, actor: User, building: Building, **fields: Any) -> Unit:
    """Create a single unit under ``building`` and audit it (``unit.create``).

    The building is supplied by the caller (resolved from the scoped URL), never
    from the client body. Only writable fields are persisted.
    """
    data = {k: v for k, v in fields.items() if k in _UNIT_WRITABLE_FIELDS}
    unit = cast(
        Unit,
        Unit.objects.create(building=building, **data),  # type: ignore[misc]
    )

    audit(
        actor=actor,
        action="unit.create",
        target=unit,
        before=None,
        after=_unit_snapshot(unit),
    )
    return unit


def generate_units(
    *,
    actor: User,
    building: Building,
    floors: int,
    per_floor: int,
    scheme: str,
    custom: list[str] | None = None,
    removed: list[str] | None = None,
) -> list[Unit]:
    """Bulk-create units for ``building`` from the generation spec (T-004 §2).

    Labels come from the pure :func:`generate_unit_labels` (the source of truth
    the UI mirrors). Labels already present on the building are skipped so the
    call is idempotent-ish (re-running adds only the missing ones). The whole
    insert is atomic, and a single ``unit.generate`` audit row records the spec
    and the labels created.
    """
    labels = generate_unit_labels(
        floors=floors,
        per_floor=per_floor,
        scheme=scheme,
        custom=custom,
        removed=removed,
    )
    existing_qs = cast("QuerySet[Unit]", Unit.objects.filter(building=building))
    existing = set(existing_qs.values_list("label", flat=True))
    to_create = [label for label in labels if label not in existing]

    with transaction.atomic():
        units = [Unit(building=building, label=label) for label in to_create]
        created_units = cast(
            "list[Unit]",
            Unit.objects.bulk_create(units),  # type: ignore[misc]
        )

    audit(
        actor=actor,
        action="unit.generate",
        target=building,
        before=None,
        after={
            "floors": floors,
            "per_floor": per_floor,
            "scheme": scheme,
            "created_labels": to_create,
        },
    )
    return created_units


def update_unit(*, actor: User, unit: Unit, **fields: Any) -> Unit:
    """Apply a partial update to ``unit`` and audit the change (``unit.update``).

    Records the before/after of exactly the fields that changed. A no-op update
    changes nothing and audits nothing.
    """
    changes = {k: v for k, v in fields.items() if k in _UNIT_WRITABLE_FIELDS}
    before_full = _unit_snapshot(unit)
    before = {k: getattr(unit, k) for k in changes}
    after = {k: v for k, v in changes.items() if v != before[k]}

    if not after:
        return unit

    for field, value in after.items():
        setattr(unit, field, value)
    unit.save(update_fields=[*after.keys(), "updated_at"])

    after_full = _unit_snapshot(unit)
    audit(
        actor=actor,
        action="unit.update",
        target=unit,
        before={k: before_full[k] for k in after},
        after={k: after_full[k] for k in after},
    )
    return unit


def delete_unit(*, actor: User, unit: Unit) -> None:
    """Soft-delete ``unit`` and audit it (``unit.delete``)."""
    before = _unit_snapshot(unit)
    unit.delete()  # soft delete (SoftDeleteModel)

    audit(
        actor=actor,
        action="unit.delete",
        target=unit,
        before=before,
        after=None,
    )
