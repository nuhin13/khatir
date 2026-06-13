"""Read-side selectors for the properties domain (T-005 §3).

Selectors are pure read functions: they return scoped, annotated querysets and
plain dicts — never write. The portfolio summary aggregates each building's unit
counts, occupancy breakdown, and total rent in a **single** annotated query (no
N+1, no Python loops, per T-005 §15). All reads are scoped through
``Building.objects.for_user`` so a user only ever sees their own portfolio.
"""

from __future__ import annotations

from decimal import Decimal
from typing import Any, TypedDict

from django.db.models import Count, DecimalField, Q, Sum, Value
from django.db.models.functions import Coalesce

from khatir.accounts.models import User

from .enums import UnitStatus
from .models import Building

_ZERO = Decimal("0.00")


class BuildingSummary(TypedDict):
    """Per-building rollup returned in the portfolio list."""

    id: str
    name: str
    area: str
    total_units: int
    occupied: int
    vacant: int
    maintenance: int
    total_rent: str


class PortfolioTotals(TypedDict):
    """Top-level totals across the whole portfolio."""

    buildings: int
    total_units: int
    occupied: int
    vacant: int
    maintenance: int
    total_rent: str


class Portfolio(TypedDict):
    """The full portfolio payload: per-building summaries + grand totals."""

    buildings: list[BuildingSummary]
    totals: PortfolioTotals


def _annotated_buildings(user: User) -> Any:
    """Buildings scoped to ``user``, annotated with unit rollups in one query.

    Counts use filtered ``Count`` so occupied/vacant/maintenance come from a
    single grouped query (no per-building round-trips). ``total_rent`` is the sum
    of every (non-deleted) unit's rent, coalesced to 0.00 for empty buildings.
    """
    rent_field = DecimalField(max_digits=12, decimal_places=2)
    # Only non-soft-deleted units count toward the rollups.
    live = Q(units__deleted_at__isnull=True)
    return (
        Building.objects.for_user(user)
        .annotate(
            total_units=Count("units", filter=live),
            occupied=Count(
                "units", filter=live & Q(units__status=UnitStatus.OCCUPIED)
            ),
            vacant=Count(
                "units", filter=live & Q(units__status=UnitStatus.VACANT)
            ),
            maintenance=Count(
                "units", filter=live & Q(units__status=UnitStatus.MAINTENANCE)
            ),
            total_rent=Coalesce(
                Sum("units__rent", filter=live),
                Value(_ZERO, output_field=rent_field),
                output_field=rent_field,
            ),
        )
        .order_by("-created_at")
    )


def portfolio_for_user(user: User) -> Portfolio:
    """Return the landlord/manager's portfolio summary (T-005 §3).

    A list of buildings — each with total units, occupancy breakdown, and rent
    sum — plus a top-level ``totals`` object. All numbers come from ORM
    annotations on a single scoped query; totals are summed over the already
    materialised rows so no extra DB round-trip is needed.
    """
    rows = list(_annotated_buildings(user))

    buildings: list[BuildingSummary] = [
        {
            "id": str(b.pk),
            "name": b.name,
            "area": b.area,
            "total_units": b.total_units,
            "occupied": b.occupied,
            "vacant": b.vacant,
            "maintenance": b.maintenance,
            "total_rent": str(b.total_rent),
        }
        for b in rows
    ]

    totals: PortfolioTotals = {
        "buildings": len(rows),
        "total_units": sum(b.total_units for b in rows),
        "occupied": sum(b.occupied for b in rows),
        "vacant": sum(b.vacant for b in rows),
        "maintenance": sum(b.maintenance for b in rows),
        "total_rent": str(sum((b.total_rent for b in rows), _ZERO)),
    }

    return {"buildings": buildings, "totals": totals}
