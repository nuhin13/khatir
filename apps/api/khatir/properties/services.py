"""Buildings service layer — business logic for create/update/delete (T-003 §2).

Views stay thin (validate → call a service → serialize). The owner is **always**
set from ``request.user`` on create (never trusted from the client, T-003 §15).
Every mutation writes an :class:`~khatir.core.models.AuditEntry` via
``core.audit.audit`` (``domain.verb`` action strings).
"""

from __future__ import annotations

from decimal import Decimal
from typing import Any, cast

from khatir.accounts.models import User
from khatir.core.audit import audit

from .models import Building

# Fields a client may write on a building (owner is server-set, never here).
_WRITABLE_FIELDS = ("name", "area", "address", "lat", "lng")


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
