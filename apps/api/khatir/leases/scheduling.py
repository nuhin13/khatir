"""Rent-schedule generation (EPIC-06 · T-002).

Given an active :class:`~khatir.leases.models.Lease`, materialise its monthly
:class:`~khatir.leases.models.RentSchedule` rows from the lease start month
through a horizon month. One row per calendar month, with the rent ``due_date``
resolved from a day-of-month that is **clamped** to the length of each month
(a ``due_day`` of 31 lands on 28/29 Feb, 30 Apr, etc.).

The core month-stepping and due-date maths live in small pure helpers so they
are trivially unit-testable. :func:`generate_schedule` is the only function that
touches the database; it is **idempotent** — periods that already exist for the
lease are skipped (guarded both in Python and by the
``leases_rentschedule_unique_lease_period`` constraint), so the roll-forward job
(T-005) can call it repeatedly and safely.

"Due day" follows the convention in ``04_coding_conventions.md`` §7: stored as an
int day-of-month and resolved to a concrete date per period here. Lease has no
``due_day`` column today, so callers pass one; absent that we fall back to
:data:`DEFAULT_DUE_DAY` (kept in sync with the seeded ``default_due_day``
SystemConfig from T-006).

``through`` may be omitted (T-003 activation calls ``generate_schedule(lease)``):
in that case we lay out a horizon of ``rent_schedule_horizon_months`` months
(config, default 12) starting from the current month, clamped to the lease end.
"""

from __future__ import annotations

import calendar
import datetime

from khatir.core.config import get_config
from khatir.leases.enums import RentScheduleStatus
from khatir.leases.models import Lease, RentSchedule

#: Fallback due day-of-month when the caller passes none. Mirrors the seeded
#: ``default_due_day`` SystemConfig (T-006).
DEFAULT_DUE_DAY = 5

#: Fallback horizon (months) when ``rent_schedule_horizon_months`` is unset and
#: the caller passes no explicit ``through``. A 12-month horizon is a typical
#: lease term.
DEFAULT_HORIZON_MONTHS = 12


def period_key(year: int, month: int) -> str:
    """Return the canonical ``YYYY-MM`` period string for *year*/*month*."""
    return f"{year:04d}-{month:02d}"


def clamp_due_day(year: int, month: int, due_day: int) -> int:
    """Clamp *due_day* to the number of days in *year*/*month*.

    e.g. ``clamp_due_day(2026, 2, 31) == 28`` and ``clamp_due_day(2024, 2, 31)
    == 29`` (leap year). A ``due_day`` already within range is returned as-is.
    """
    days_in_month = calendar.monthrange(year, month)[1]
    return min(due_day, days_in_month)


def resolve_due_date(year: int, month: int, due_day: int) -> datetime.date:
    """Resolve the concrete due date for a period, clamping the day-of-month."""
    return datetime.date(year, month, clamp_due_day(year, month, due_day))


def iter_months(
    start: datetime.date, through: datetime.date
) -> list[tuple[int, int]]:
    """Yield ``(year, month)`` tuples for every month from *start* to *through*.

    Inclusive of both endpoints' months and order-preserving (ascending).
    Returns an empty list if *through* precedes *start*'s month.
    """
    months: list[tuple[int, int]] = []
    year, month = start.year, start.month
    while (year, month) <= (through.year, through.month):
        months.append((year, month))
        if month == 12:
            year, month = year + 1, 1
        else:
            month += 1
    return months


def _default_through(lease: Lease) -> datetime.date:
    """Horizon month when no explicit ``through`` is given (T-003 activation).

    Lay out ``rent_schedule_horizon_months`` months ahead of the current month,
    clamped to the lease end so we never schedule past the term.
    """
    months = int(get_config("rent_schedule_horizon_months", DEFAULT_HORIZON_MONTHS))
    today = datetime.date.today()
    year, month = today.year, today.month
    for _ in range(months):
        if month == 12:
            year, month = year + 1, 1
        else:
            month += 1
    horizon = datetime.date(year, month, 1)
    end = lease.end_date
    if end is not None and (horizon.year, horizon.month) > (end.year, end.month):
        return datetime.date(end.year, end.month, 1)
    return horizon


def generate_schedule(
    lease: Lease,
    through: datetime.date | None = None,
    *,
    due_day: int | None = None,
) -> list[RentSchedule]:
    """Generate (idempotently) rent-schedule rows for *lease* up to *through*.

    For every month from the lease's ``start_date`` month through the month of
    *through* (inclusive), ensure a :class:`RentSchedule` row exists with:

    * ``period`` — the ``YYYY-MM`` key,
    * ``due_day`` — the (unclamped) intended day-of-month,
    * ``due_date`` — that day clamped to the month length,
    * ``amount`` — the lease's current ``rent``,
    * ``status`` — ``pending``.

    When *through* is omitted, a config-driven horizon is used (see
    :func:`_default_through`).

    Already-present periods are left untouched (idempotent). The partial first
    month — when the lease starts mid-month — still produces a full schedule row
    for that month; pro-rating of the amount is a billing concern, not a
    scheduling one.

    Returns the rows **created** by this call (existing rows are not returned),
    so a no-op re-run returns an empty list.
    """
    if through is None:
        through = _default_through(lease)

    resolved_due_day = DEFAULT_DUE_DAY if due_day is None else due_day

    existing_periods = set(
        RentSchedule.objects.filter(lease=lease).values_list("period", flat=True)
    )

    to_create: list[RentSchedule] = []
    for year, month in iter_months(lease.start_date, through):
        period = period_key(year, month)
        if period in existing_periods:
            continue
        to_create.append(
            RentSchedule(
                lease=lease,
                period=period,
                due_day=resolved_due_day,
                due_date=resolve_due_date(year, month, resolved_due_day),
                amount=lease.rent,
                status=RentScheduleStatus.PENDING,
            )
        )

    if to_create:
        RentSchedule.objects.bulk_create(to_create)
    return to_create
