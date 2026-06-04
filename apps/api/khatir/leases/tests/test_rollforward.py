"""Tests for the monthly roll-forward + overdue Celery task (T-005 §12).

Runs Celery eagerly (``CELERY_TASK_ALWAYS_EAGER=True`` in test settings) so the
task executes synchronously. Dates are computed relative to *today* (UTC) so
the assertions hold on any run date without freezing the clock.
"""

from __future__ import annotations

import datetime
from decimal import Decimal

import pytest
from django.utils import timezone

from khatir.core.models import SystemConfig
from khatir.leases.enums import LeaseStatus, RentScheduleStatus
from khatir.leases.models import Lease, RentSchedule
from khatir.leases.scheduling import period_key
from khatir.leases.tasks import (
    DEFAULT_OVERDUE_GRACE_DAYS,
    ROLL_FORWARD_MONTHS,
    add_months,
    roll_schedules_and_flag_overdue,
)

from .factories import LeaseFactory, RentScheduleFactory

pytestmark = pytest.mark.django_db


def _set_grace(days: int) -> None:
    """Seed the overdue grace SystemConfig used by the task."""
    SystemConfig.objects.update_or_create(
        key="rent_overdue_grace_days",
        defaults={"value": str(days), "type": "int"},
    )


# ---------------------------------------------------------------------------
# Pure helper
# ---------------------------------------------------------------------------


def test_add_months_basic() -> None:
    assert add_months(datetime.date(2026, 1, 15), 1) == datetime.date(2026, 2, 15)
    assert add_months(datetime.date(2026, 11, 10), 2) == datetime.date(2027, 1, 10)


def test_add_months_clamps_day() -> None:
    # Jan 31 + 1 month -> Feb 28 (non-leap), Feb 29 (leap).
    assert add_months(datetime.date(2026, 1, 31), 1) == datetime.date(2026, 2, 28)
    assert add_months(datetime.date(2024, 1, 31), 1) == datetime.date(2024, 2, 29)


# ---------------------------------------------------------------------------
# Roll-forward
# ---------------------------------------------------------------------------


def test_rollforward_extends() -> None:
    """An active lease with no schedule gets rows out to the horizon."""
    today = timezone.now().date()
    # Lease started this month, runs well beyond the horizon.
    lease: Lease = LeaseFactory(  # type: ignore[assignment]
        start_date=today.replace(day=1),
        end_date=add_months(today, 24),
        status=LeaseStatus.ACTIVE,
    )

    result = roll_schedules_and_flag_overdue()

    horizon = add_months(today, ROLL_FORWARD_MONTHS)
    expected_periods = {
        period_key(today.year, today.month),
        period_key(horizon.year, horizon.month),
    }
    periods = set(
        RentSchedule.objects.filter(lease=lease).values_list("period", flat=True)
    )
    assert expected_periods <= periods
    assert result["rows_created"] >= len(expected_periods)
    assert result["leases"] == 1


def test_rollforward_is_idempotent() -> None:
    """A second run creates no further rows."""
    today = timezone.now().date()
    LeaseFactory(
        start_date=today.replace(day=1),
        end_date=add_months(today, 24),
        status=LeaseStatus.ACTIVE,
    )

    first = roll_schedules_and_flag_overdue()
    assert first["rows_created"] > 0

    before = RentSchedule.objects.count()
    second = roll_schedules_and_flag_overdue()
    assert second["rows_created"] == 0
    assert RentSchedule.objects.count() == before


def test_rollforward_caps_at_lease_end() -> None:
    """Schedule never extends past the lease end_date."""
    today = timezone.now().date()
    end = today.replace(day=28)  # lease ends this month
    lease: Lease = LeaseFactory(  # type: ignore[assignment]
        start_date=today.replace(day=1),
        end_date=end,
        status=LeaseStatus.ACTIVE,
    )

    roll_schedules_and_flag_overdue()

    horizon = add_months(today, ROLL_FORWARD_MONTHS)
    horizon_period = period_key(horizon.year, horizon.month)
    periods = set(
        RentSchedule.objects.filter(lease=lease).values_list("period", flat=True)
    )
    # The next-month horizon period must NOT be generated (capped at end_date).
    assert horizon_period not in periods
    assert period_key(today.year, today.month) in periods


def test_rollforward_skips_inactive_leases() -> None:
    """Draft / ended / terminated leases are left untouched."""
    today = timezone.now().date()
    for status in (LeaseStatus.DRAFT, LeaseStatus.ENDED, LeaseStatus.TERMINATED):
        LeaseFactory(
            start_date=today.replace(day=1),
            end_date=add_months(today, 12),
            status=status,
        )

    result = roll_schedules_and_flag_overdue()

    assert result["leases"] == 0
    assert RentSchedule.objects.count() == 0


# ---------------------------------------------------------------------------
# Overdue flagging
# ---------------------------------------------------------------------------


def test_overdue_flagged_after_grace() -> None:
    """A pending row past due_date + grace becomes overdue."""
    _set_grace(3)
    today = timezone.now().date()
    lease: Lease = LeaseFactory(  # type: ignore[assignment]
        start_date=add_months(today, -6),
        end_date=add_months(today, 6),
        status=LeaseStatus.ACTIVE,
    )
    # Due 10 days ago — well past the 3-day grace window.
    overdue_date = today - datetime.timedelta(days=10)
    row: RentSchedule = RentScheduleFactory(  # type: ignore[assignment]
        lease=lease,
        period="2000-01",  # arbitrary historic period, avoids roll-forward overlap
        due_date=overdue_date,
        due_day=overdue_date.day,
        status=RentScheduleStatus.PENDING,
    )

    result = roll_schedules_and_flag_overdue()

    row.refresh_from_db()
    assert row.status == RentScheduleStatus.OVERDUE
    assert result["rows_overdue"] >= 1


def test_within_grace_not_flagged() -> None:
    """A row due yesterday with a 3-day grace stays pending."""
    _set_grace(3)
    today = timezone.now().date()
    lease: Lease = LeaseFactory(  # type: ignore[assignment]
        start_date=add_months(today, -6),
        end_date=add_months(today, 6),
        status=LeaseStatus.ACTIVE,
    )
    due = today - datetime.timedelta(days=1)
    row: RentSchedule = RentScheduleFactory(  # type: ignore[assignment]
        lease=lease,
        period="2000-02",
        due_date=due,
        due_day=due.day,
        status=RentScheduleStatus.PENDING,
    )

    roll_schedules_and_flag_overdue()

    row.refresh_from_db()
    assert row.status == RentScheduleStatus.PENDING


def test_overdue_uses_config_grace() -> None:
    """A larger configured grace keeps an otherwise-overdue row pending."""
    _set_grace(30)
    today = timezone.now().date()
    lease: Lease = LeaseFactory(  # type: ignore[assignment]
        start_date=add_months(today, -6),
        end_date=add_months(today, 6),
        status=LeaseStatus.ACTIVE,
    )
    due = today - datetime.timedelta(days=10)  # only 10 days late < 30 grace
    row: RentSchedule = RentScheduleFactory(  # type: ignore[assignment]
        lease=lease,
        period="2000-03",
        due_date=due,
        due_day=due.day,
        status=RentScheduleStatus.PENDING,
    )

    roll_schedules_and_flag_overdue()

    row.refresh_from_db()
    assert row.status == RentScheduleStatus.PENDING


def test_overdue_falls_back_to_default_grace() -> None:
    """The default grace applies (T-006 seeds it to DEFAULT_OVERDUE_GRACE_DAYS)."""
    grace = SystemConfig.objects.filter(key="rent_overdue_grace_days").first()
    assert grace is None or int(grace.value) == DEFAULT_OVERDUE_GRACE_DAYS
    today = timezone.now().date()
    lease: Lease = LeaseFactory(  # type: ignore[assignment]
        start_date=add_months(today, -6),
        end_date=add_months(today, 6),
        status=LeaseStatus.ACTIVE,
    )
    due = today - datetime.timedelta(days=DEFAULT_OVERDUE_GRACE_DAYS + 5)
    row: RentSchedule = RentScheduleFactory(  # type: ignore[assignment]
        lease=lease,
        period="2000-04",
        due_date=due,
        due_day=due.day,
        status=RentScheduleStatus.PENDING,
    )

    roll_schedules_and_flag_overdue()

    row.refresh_from_db()
    assert row.status == RentScheduleStatus.OVERDUE


def test_paid_rows_never_flagged_overdue() -> None:
    """A paid row past grace is never reverted to overdue."""
    _set_grace(3)
    today = timezone.now().date()
    lease: Lease = LeaseFactory(  # type: ignore[assignment]
        start_date=add_months(today, -6),
        end_date=add_months(today, 6),
        status=LeaseStatus.ACTIVE,
    )
    due = today - datetime.timedelta(days=30)
    row: RentSchedule = RentScheduleFactory(  # type: ignore[assignment]
        lease=lease,
        period="2000-05",
        due_date=due,
        due_day=due.day,
        amount=Decimal("15000.00"),
        status=RentScheduleStatus.PAID,
    )

    roll_schedules_and_flag_overdue()

    row.refresh_from_db()
    assert row.status == RentScheduleStatus.PAID


def test_overdue_ignores_inactive_lease_rows() -> None:
    """Past-grace rows on a terminated lease are not flagged."""
    _set_grace(3)
    today = timezone.now().date()
    lease: Lease = LeaseFactory(  # type: ignore[assignment]
        start_date=add_months(today, -6),
        end_date=add_months(today, 6),
        status=LeaseStatus.TERMINATED,
    )
    due = today - datetime.timedelta(days=30)
    row: RentSchedule = RentScheduleFactory(  # type: ignore[assignment]
        lease=lease,
        period="2000-06",
        due_date=due,
        due_day=due.day,
        status=RentScheduleStatus.PENDING,
    )

    roll_schedules_and_flag_overdue()

    row.refresh_from_db()
    assert row.status == RentScheduleStatus.PENDING
