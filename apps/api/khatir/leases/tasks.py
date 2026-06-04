"""Leases Celery tasks — monthly roll-forward + overdue flagging (EPIC-06 · T-005).

A single Beat-scheduled task, :func:`roll_schedules_and_flag_overdue`, keeps
every active lease's rent schedule healthy:

1. **Roll-forward** — extend each active lease's :class:`RentSchedule` rows
   forward so they cover up to a rolling *horizon* (today plus
   :data:`ROLL_FORWARD_MONTHS` months), never past the lease ``end_date``. This
   reuses the idempotent :func:`~khatir.leases.scheduling.generate_schedule`
   from T-002, so re-running the task creates no duplicates.
2. **Overdue flagging** — any still-unpaid schedule row whose
   ``due_date + grace`` has elapsed (relative to *today*, UTC) is marked
   ``overdue``. The grace window is read from the admin-tunable
   ``rent_overdue_grace_days`` SystemConfig (EPIC-06.T-006), falling back to
   :data:`DEFAULT_OVERDUE_GRACE_DAYS` if unset.

All date maths are UTC: the task derives "today" from ``timezone.now()`` (the
project pins ``TIME_ZONE = "UTC"``), so the result is deterministic regardless
of the worker's local clock. The whole task is idempotent — safe to run daily.
"""

from __future__ import annotations

import datetime
from typing import cast

from celery import shared_task
from django.db.models import Q, QuerySet
from django.utils import timezone

from khatir.core.config import get_config
from khatir.leases.enums import LeaseStatus, RentScheduleStatus
from khatir.leases.models import Lease, RentSchedule
from khatir.leases.scheduling import generate_schedule

#: How many whole months ahead of *today* the schedule is materialised. One
#: month of look-ahead keeps the next request/reminder cycle primed.
ROLL_FORWARD_MONTHS = 1

#: SystemConfig key for the overdue grace window (seeded by EPIC-06.T-006).
OVERDUE_GRACE_CONFIG_KEY = "rent_overdue_grace_days"

#: Fallback grace window (days) when the SystemConfig key is absent. Mirrors the
#: seeded ``rent_overdue_grace_days`` default.
DEFAULT_OVERDUE_GRACE_DAYS = 3

#: Schedule rows in these statuses are still collectible and therefore eligible
#: to be flagged overdue. ``paid`` and ``overdue`` rows are left untouched.
_OVERDUE_ELIGIBLE_STATUSES = (
    RentScheduleStatus.PENDING,
    RentScheduleStatus.REQUESTED,
)


def add_months(date: datetime.date, months: int) -> datetime.date:
    """Return *date* shifted forward by *months* whole calendar months.

    The day-of-month is clamped to the target month's length so e.g. Jan 31 +
    1 month lands on the last day of February. Used to compute the rolling
    roll-forward horizon without pulling in a date-arithmetic dependency.
    """
    import calendar

    zero_based = date.month - 1 + months
    year = date.year + zero_based // 12
    month = zero_based % 12 + 1
    day = min(date.day, calendar.monthrange(year, month)[1])
    return datetime.date(year, month, day)


def _roll_forward(lease: Lease, horizon: datetime.date) -> int:
    """Extend *lease*'s schedule up to *horizon*, capped at its ``end_date``.

    Returns the number of new :class:`RentSchedule` rows created.
    """
    through = min(horizon, lease.end_date)
    created = generate_schedule(lease, through)
    return len(created)


def _flag_overdue(today: datetime.date, grace_days: int) -> int:
    """Mark eligible unpaid schedules whose grace window has lapsed overdue.

    A row is overdue once ``due_date + grace_days < today`` and its status is
    still pending/requested. Returns the number of rows transitioned.
    """
    cutoff = today - datetime.timedelta(days=grace_days)
    return (
        RentSchedule.objects.filter(
            Q(status__in=_OVERDUE_ELIGIBLE_STATUSES),
            lease__status=LeaseStatus.ACTIVE,
            due_date__lt=cutoff,
        ).update(status=RentScheduleStatus.OVERDUE)
    )


@shared_task  # type: ignore[untyped-decorator]  # celery has no py.typed marker
def roll_schedules_and_flag_overdue() -> dict[str, int]:
    """Roll active leases forward and flag overdue rent (Beat-scheduled).

    Idempotent. Returns a small summary dict (``leases``, ``rows_created``,
    ``rows_overdue``) for logging/observability.
    """
    today = timezone.now().date()
    horizon = add_months(today, ROLL_FORWARD_MONTHS)
    grace_days = int(
        get_config(OVERDUE_GRACE_CONFIG_KEY, default=DEFAULT_OVERDUE_GRACE_DAYS)
    )

    # ``SoftDeleteModel.objects`` is statically typed against the abstract base,
    # so cast to a concrete Lease queryset for field/iterator inference.
    active_leases = cast(
        "QuerySet[Lease]",
        Lease.objects.filter(status=LeaseStatus.ACTIVE),  # type: ignore[misc]
    )

    rows_created = 0
    lease_count = 0
    for lease in active_leases.iterator():
        lease_count += 1
        rows_created += _roll_forward(lease, horizon)

    rows_overdue = _flag_overdue(today, grace_days)

    return {
        "leases": lease_count,
        "rows_created": rows_created,
        "rows_overdue": rows_overdue,
    }
