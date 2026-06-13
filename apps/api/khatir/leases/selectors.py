"""Read-side selectors for the leases domain (T-004 §3).

Selectors are pure read functions: they return scoped querysets / model
instances and never write. Every read is scoped through ``for_user`` so a user
only ever sees their own leases — a missing scope is a P0 security bug
(``04_coding_conventions.md`` §3).
"""

from __future__ import annotations

from typing import Any, cast

from django.db.models import QuerySet

from .enums import LeaseStatus
from .models import Lease, RentSchedule


def schedule_for_lease(lease: Lease) -> QuerySet[RentSchedule]:
    """Return *lease*'s rent-schedule rows, ordered chronologically by period.

    The lease must already be one the caller may see (the view resolves it
    through ``Lease.objects.for_user`` / ``get_object`` first), so this is a
    straight ordered read of its child rows.
    """
    return RentSchedule.objects.filter(lease=lease).order_by("period")


def active_lease_for_unit(unit_id: Any, *, user: Any) -> Lease | None:
    """Return the single **active** lease for *unit_id*, scoped to ``user``.

    Returns ``None`` when the unit has no active lease (the view turns that into
    a 404). Scoping is applied through ``Lease.objects.for_user`` so a lease the
    caller may not see is never returned — even if the unit somehow leaked.
    """
    return cast(
        "Lease | None",
        Lease.objects.for_user(user)
        .filter(unit_id=unit_id, status=LeaseStatus.ACTIVE)
        .select_related("tenant")
        .first(),
    )
