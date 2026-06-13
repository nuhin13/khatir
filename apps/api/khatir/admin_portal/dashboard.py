"""Platform-dashboard KPI selectors — EPIC-11.T-005.

Aggregates platform-wide metrics for the admin dashboard. Unlike every
customer-facing selector these are **not** ``for_user`` scoped: an admin sees
the whole platform. The computation touches several app tables (accounts,
properties, leases/rent, billing, dmpforms) but only reads — it never mutates.

The whole payload is expensive enough (several COUNT / SUM aggregates) that we
memoise it in the cache for five minutes; the view layer reads through
:func:`get_platform_dashboard`. ``health`` reflects live DB / cache reachability
and is therefore computed *outside* the cached block so it is always fresh.
"""

from __future__ import annotations

from decimal import Decimal
from typing import Any

from django.core.cache import cache
from django.db import DatabaseError, connection
from django.db.models import Sum
from django.utils import timezone

from khatir.accounts.models import User
from khatir.billing.enums import SubscriptionStatus
from khatir.billing.models import Subscription
from khatir.core.enums import Role
from khatir.dmpforms.models import DMPFormRecord
from khatir.properties.enums import UnitStatus
from khatir.properties.models import Building, Unit
from khatir.rent.models import Payment

#: Cache key + TTL for the (expensive) aggregate block. ``health`` is excluded.
CACHE_KEY = "admin:platform_dashboard:v1"
CACHE_TTL_SECONDS = 300  # 5 minutes (task §2).


_TWO_PLACES = Decimal("0.01")


def _money(value: Decimal | None) -> Decimal:
    """Normalise a (possibly ``None``) aggregate to a 2-dp Taka amount."""
    return (value or Decimal("0")).quantize(_TWO_PLACES)


def _kpis() -> dict[str, Any]:
    """Compute the platform KPI aggregates (the cached portion)."""
    total_users = User.objects.count()
    # An "active landlord" is a landlord account that actually owns property —
    # i.e. a landlord with at least one (non-deleted) building.
    active_landlords = (
        Building.objects.filter(owner__role=Role.LANDLORD)
        .values("owner_id")
        .distinct()
        .count()
    )

    total_properties = Building.objects.count()
    total_units = Unit.objects.count()
    occupied_units = Unit.objects.filter(status=UnitStatus.OCCUPIED).count()

    # Rent collected = the requested amount of every request that has a
    # verified Payment row. Summing the request amount (not a payment column)
    # because the Payment model carries no monetary field of its own.
    collected_qs = Payment.objects.all()
    all_time = _money(
        collected_qs.aggregate(total=Sum("rent_request__amount"))["total"]
    )

    month_start = timezone.now().replace(
        day=1, hour=0, minute=0, second=0, microsecond=0
    )
    this_month = _money(
        collected_qs.filter(created_at__gte=month_start).aggregate(
            total=Sum("rent_request__amount")
        )["total"]
    )

    dmp_forms_generated = DMPFormRecord.objects.count()
    active_subscriptions = Subscription.objects.filter(
        status=SubscriptionStatus.ACTIVE
    ).count()

    return {
        "total_users": total_users,
        "active_landlords": active_landlords,
        "total_properties": total_properties,
        "total_units": total_units,
        "occupied_units": occupied_units,
        "total_rent_collected": {
            "all_time": str(all_time),
            "this_month": str(this_month),
        },
        "dmp_forms_generated": dmp_forms_generated,
        "active_subscriptions": active_subscriptions,
    }


def _db_ok() -> bool:
    """True when a trivial query against the primary DB succeeds."""
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()
    except DatabaseError:
        return False
    return True


def _cache_ok() -> bool:
    """True when the cache (Redis in prod) round-trips a probe value."""
    probe_key = "admin:platform_dashboard:health_probe"
    try:
        cache.set(probe_key, "1", timeout=5)
        return cache.get(probe_key) == "1"
    except Exception:  # noqa: BLE001 - any backend failure means "not reachable"
        return False


def _health() -> dict[str, Any]:
    """Live app + dependency reachability (never cached)."""
    db_ok = _db_ok()
    cache_ok = _cache_ok()
    return {
        "app": "ok",
        "database": "ok" if db_ok else "down",
        "cache": "ok" if cache_ok else "down",
        "status": "ok" if (db_ok and cache_ok) else "degraded",
    }


def get_platform_dashboard() -> dict[str, Any]:
    """Return the platform dashboard payload (KPIs cached 5 min + live health).

    The KPI aggregate block is memoised under :data:`CACHE_KEY`; ``health`` is
    always recomputed so the admin sees current DB/cache reachability.
    """
    kpis = cache.get(CACHE_KEY)
    if kpis is None:
        kpis = _kpis()
        cache.set(CACHE_KEY, kpis, timeout=CACHE_TTL_SECONDS)
    return {**kpis, "health": _health()}
