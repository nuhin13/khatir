"""Tests for the rent-schedule generation service (T-002 §12).

Covers the pure helpers (month iteration, due-day clamping) and the
DB-touching :func:`generate_schedule`: normal multi-month generation, month-end
clamping (Feb non-leap + leap), idempotency, and the partial-first-month case.
"""

from __future__ import annotations

import datetime
from decimal import Decimal

import pytest

from khatir.leases.enums import LeaseStatus, RentScheduleStatus
from khatir.leases.models import Lease, RentSchedule
from khatir.leases.scheduling import (
    DEFAULT_DUE_DAY,
    clamp_due_day,
    generate_schedule,
    iter_months,
    period_key,
    resolve_due_date,
)

from .factories import LeaseFactory, RentScheduleFactory

pytestmark = pytest.mark.django_db


# ---------------------------------------------------------------------------
# Pure helpers (no DB)
# ---------------------------------------------------------------------------


def test_period_key_zero_pads() -> None:
    assert period_key(2026, 1) == "2026-01"
    assert period_key(2026, 12) == "2026-12"


def test_clamp_due_day_within_range_unchanged() -> None:
    assert clamp_due_day(2026, 1, 5) == 5
    assert clamp_due_day(2026, 1, 31) == 31  # January has 31 days


def test_clamp_due_day_feb_non_leap() -> None:
    assert clamp_due_day(2026, 2, 31) == 28


def test_clamp_due_day_feb_leap() -> None:
    assert clamp_due_day(2024, 2, 31) == 29


def test_clamp_due_day_thirty_day_month() -> None:
    assert clamp_due_day(2026, 4, 31) == 30  # April has 30 days


def test_resolve_due_date_clamps() -> None:
    assert resolve_due_date(2026, 2, 31) == datetime.date(2026, 2, 28)
    assert resolve_due_date(2024, 2, 31) == datetime.date(2024, 2, 29)
    assert resolve_due_date(2026, 1, 5) == datetime.date(2026, 1, 5)


def test_iter_months_inclusive_range() -> None:
    months = iter_months(datetime.date(2026, 1, 15), datetime.date(2026, 3, 1))
    assert months == [(2026, 1), (2026, 2), (2026, 3)]


def test_iter_months_crosses_year_boundary() -> None:
    months = iter_months(datetime.date(2026, 11, 1), datetime.date(2027, 2, 1))
    assert months == [(2026, 11), (2026, 12), (2027, 1), (2027, 2)]


def test_iter_months_single_month() -> None:
    months = iter_months(datetime.date(2026, 5, 10), datetime.date(2026, 5, 28))
    assert months == [(2026, 5)]


def test_iter_months_through_before_start_is_empty() -> None:
    months = iter_months(datetime.date(2026, 5, 1), datetime.date(2026, 4, 1))
    assert months == []


# ---------------------------------------------------------------------------
# generate_schedule — normal generation
# ---------------------------------------------------------------------------


def test_generate_months_creates_one_row_per_month() -> None:
    lease: Lease = LeaseFactory(  # type: ignore[assignment]
        start_date=datetime.date(2026, 1, 1),
        end_date=datetime.date(2026, 12, 31),
        rent=Decimal("15000.00"),
        status=LeaseStatus.ACTIVE,
    )
    created = generate_schedule(lease, datetime.date(2026, 3, 31), due_day=5)

    assert len(created) == 3
    rows = list(RentSchedule.objects.filter(lease=lease).order_by("period"))
    assert [r.period for r in rows] == ["2026-01", "2026-02", "2026-03"]


def test_generate_sets_amount_status_due_date() -> None:
    lease: Lease = LeaseFactory(  # type: ignore[assignment]
        start_date=datetime.date(2026, 1, 1),
        rent=Decimal("17500.00"),
        status=LeaseStatus.ACTIVE,
    )
    generate_schedule(lease, datetime.date(2026, 1, 31), due_day=5)

    row = RentSchedule.objects.get(lease=lease, period="2026-01")
    assert row.amount == Decimal("17500.00")
    assert row.status == RentScheduleStatus.PENDING
    assert row.due_day == 5
    assert row.due_date == datetime.date(2026, 1, 5)


def test_generate_uses_default_due_day_when_none() -> None:
    lease: Lease = LeaseFactory(  # type: ignore[assignment]
        start_date=datetime.date(2026, 1, 1),
        status=LeaseStatus.ACTIVE,
    )
    generate_schedule(lease, datetime.date(2026, 1, 31))

    row = RentSchedule.objects.get(lease=lease, period="2026-01")
    assert row.due_day == DEFAULT_DUE_DAY
    assert row.due_date == datetime.date(2026, 1, DEFAULT_DUE_DAY)


# ---------------------------------------------------------------------------
# generate_schedule — month-end clamping
# ---------------------------------------------------------------------------


def test_due_day_clamp_feb() -> None:
    """A due_day of 31 clamps to 28 in (non-leap) Feb, 31 in Jan/Mar."""
    lease: Lease = LeaseFactory(  # type: ignore[assignment]
        start_date=datetime.date(2026, 1, 1),
        status=LeaseStatus.ACTIVE,
    )
    generate_schedule(lease, datetime.date(2026, 3, 31), due_day=31)

    jan = RentSchedule.objects.get(lease=lease, period="2026-01")
    feb = RentSchedule.objects.get(lease=lease, period="2026-02")
    mar = RentSchedule.objects.get(lease=lease, period="2026-03")
    assert jan.due_date == datetime.date(2026, 1, 31)
    assert feb.due_date == datetime.date(2026, 2, 28)
    assert mar.due_date == datetime.date(2026, 3, 31)
    # The intended day-of-month is preserved on the row, only the date clamps.
    assert feb.due_day == 31


def test_due_day_clamp_feb_leap_year() -> None:
    lease: Lease = LeaseFactory(  # type: ignore[assignment]
        start_date=datetime.date(2024, 2, 1),
        status=LeaseStatus.ACTIVE,
    )
    generate_schedule(lease, datetime.date(2024, 2, 29), due_day=31)

    feb = RentSchedule.objects.get(lease=lease, period="2024-02")
    assert feb.due_date == datetime.date(2024, 2, 29)


# ---------------------------------------------------------------------------
# generate_schedule — idempotency
# ---------------------------------------------------------------------------


def test_idempotent_no_duplicate_periods() -> None:
    lease: Lease = LeaseFactory(  # type: ignore[assignment]
        start_date=datetime.date(2026, 1, 1),
        status=LeaseStatus.ACTIVE,
    )
    first = generate_schedule(lease, datetime.date(2026, 3, 31), due_day=5)
    second = generate_schedule(lease, datetime.date(2026, 3, 31), due_day=5)

    assert len(first) == 3
    assert second == []  # nothing new created on re-run
    assert RentSchedule.objects.filter(lease=lease).count() == 3


def test_idempotent_roll_forward_extends_only_new_months() -> None:
    """A second run with a later horizon adds only the new months."""
    lease: Lease = LeaseFactory(  # type: ignore[assignment]
        start_date=datetime.date(2026, 1, 1),
        status=LeaseStatus.ACTIVE,
    )
    generate_schedule(lease, datetime.date(2026, 2, 28), due_day=5)
    created = generate_schedule(lease, datetime.date(2026, 4, 30), due_day=5)

    assert [r.period for r in created] == ["2026-03", "2026-04"]
    periods = set(
        RentSchedule.objects.filter(lease=lease).values_list("period", flat=True)
    )
    assert periods == {"2026-01", "2026-02", "2026-03", "2026-04"}


def test_idempotent_skips_preexisting_row() -> None:
    """An existing schedule row for a period is left untouched."""
    lease: Lease = LeaseFactory(  # type: ignore[assignment]
        start_date=datetime.date(2026, 1, 1),
        rent=Decimal("15000.00"),
        status=LeaseStatus.ACTIVE,
    )
    RentScheduleFactory(
        lease=lease,
        period="2026-01",
        due_day=10,
        due_date=datetime.date(2026, 1, 10),
        amount=Decimal("99999.00"),
        status=RentScheduleStatus.PAID,
    )

    created = generate_schedule(lease, datetime.date(2026, 2, 28), due_day=5)

    assert [r.period for r in created] == ["2026-02"]
    untouched = RentSchedule.objects.get(lease=lease, period="2026-01")
    assert untouched.amount == Decimal("99999.00")
    assert untouched.status == RentScheduleStatus.PAID
    assert untouched.due_day == 10


# ---------------------------------------------------------------------------
# generate_schedule — partial first month
# ---------------------------------------------------------------------------


def test_partial_first_month_still_gets_a_row() -> None:
    """A lease starting mid-month still produces a full row for that month."""
    lease: Lease = LeaseFactory(  # type: ignore[assignment]
        start_date=datetime.date(2026, 1, 20),
        status=LeaseStatus.ACTIVE,
    )
    created = generate_schedule(lease, datetime.date(2026, 2, 28), due_day=5)

    assert [r.period for r in created] == ["2026-01", "2026-02"]
    jan = RentSchedule.objects.get(lease=lease, period="2026-01")
    assert jan.due_date == datetime.date(2026, 1, 5)


def test_through_before_start_creates_nothing() -> None:
    lease: Lease = LeaseFactory(  # type: ignore[assignment]
        start_date=datetime.date(2026, 5, 1),
        status=LeaseStatus.ACTIVE,
    )
    created = generate_schedule(lease, datetime.date(2026, 4, 1), due_day=5)

    assert created == []
    assert RentSchedule.objects.filter(lease=lease).count() == 0
