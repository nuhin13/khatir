"""Tests for the ``Lease`` and ``RentSchedule`` models (T-001 §12)."""

from __future__ import annotations

import datetime
from decimal import Decimal

import pytest
from django.db import IntegrityError, models

from khatir.leases.enums import LeaseStatus, RentScheduleStatus
from khatir.leases.models import Lease, RentSchedule

from .factories import LeaseFactory, RentScheduleFactory

pytestmark = pytest.mark.django_db


# ---------------------------------------------------------------------------
# Lease
# ---------------------------------------------------------------------------


def test_lease_create() -> None:
    lease: Lease = LeaseFactory(status=LeaseStatus.ACTIVE)  # type: ignore[assignment]
    assert lease.pk is not None
    assert lease.status == LeaseStatus.ACTIVE
    assert lease.unit_id is not None
    assert lease.tenant_id is not None
    assert lease.landlord_id is not None


def test_lease_default_status_is_draft() -> None:
    lease: Lease = LeaseFactory()  # type: ignore[assignment]
    lease.refresh_from_db()
    assert lease.status == LeaseStatus.DRAFT


def test_lease_money_is_decimal() -> None:
    lease: Lease = LeaseFactory(rent=Decimal("18500.00"), advance=Decimal("37000.00"))  # type: ignore[assignment]
    lease.refresh_from_db()
    assert lease.rent == Decimal("18500.00")
    assert lease.advance == Decimal("37000.00")


def test_lease_rent_field_is_decimal_field() -> None:
    rent_field = Lease._meta.get_field("rent")
    assert isinstance(rent_field, models.DecimalField)
    assert rent_field.max_digits == 12
    assert rent_field.decimal_places == 2


def test_lease_advance_field_is_decimal_field() -> None:
    advance_field = Lease._meta.get_field("advance")
    assert isinstance(advance_field, models.DecimalField)
    assert advance_field.max_digits == 12
    assert advance_field.decimal_places == 2


def test_lease_dates() -> None:
    lease: Lease = LeaseFactory(  # type: ignore[assignment]
        start_date=datetime.date(2026, 1, 1),
        end_date=datetime.date(2026, 12, 31),
    )
    lease.refresh_from_db()
    assert lease.start_date == datetime.date(2026, 1, 1)
    assert lease.end_date == datetime.date(2026, 12, 31)


def test_lease_str() -> None:
    lease: Lease = LeaseFactory()  # type: ignore[assignment]
    assert f"Lease #{lease.pk}" in str(lease)
    assert f"unit {lease.unit_id}" in str(lease)
    assert f"tenant {lease.tenant_id}" in str(lease)


def test_lease_soft_delete() -> None:
    lease: Lease = LeaseFactory()  # type: ignore[assignment]
    pk = lease.pk
    lease.delete()
    assert lease.is_deleted is True
    assert Lease.objects.filter(pk=pk).count() == 0
    assert Lease.all_objects.filter(pk=pk).count() == 1


def test_lease_signed_pdf_ref_defaults_empty() -> None:
    lease: Lease = LeaseFactory()  # type: ignore[assignment]
    lease.refresh_from_db()
    assert lease.signed_pdf_ref == ""


def test_lease_unit_fk_is_protect() -> None:
    field = Lease._meta.get_field("unit")
    assert isinstance(field, models.ForeignKey)
    assert field.remote_field.on_delete is models.PROTECT


def test_lease_tenant_fk_is_protect() -> None:
    field = Lease._meta.get_field("tenant")
    assert isinstance(field, models.ForeignKey)
    assert field.remote_field.on_delete is models.PROTECT


def test_lease_landlord_fk_is_protect() -> None:
    field = Lease._meta.get_field("landlord")
    assert isinstance(field, models.ForeignKey)
    assert field.remote_field.on_delete is models.PROTECT


# --- LeaseStatus matches enums.md -------------------------------------------


def test_lease_status_values_match_spec() -> None:
    assert set(LeaseStatus.values) == {"draft", "active", "ended", "terminated"}


# --- Lease indexes -----------------------------------------------------------


def test_lease_indexes_include_landlord_status() -> None:
    index_field_sets = {tuple(idx.fields) for idx in Lease._meta.indexes}
    assert ("landlord", "status") in index_field_sets


def test_lease_indexes_include_unit() -> None:
    index_field_sets = {tuple(idx.fields) for idx in Lease._meta.indexes}
    assert ("unit",) in index_field_sets


# ---------------------------------------------------------------------------
# RentSchedule
# ---------------------------------------------------------------------------


def test_schedule_create() -> None:
    schedule: RentSchedule = RentScheduleFactory()  # type: ignore[assignment]
    assert schedule.pk is not None
    assert schedule.lease_id is not None
    assert schedule.period == "2026-01"
    assert schedule.due_day == 5
    assert schedule.due_date == datetime.date(2026, 1, 5)


def test_schedule_default_status_is_pending() -> None:
    schedule: RentSchedule = RentScheduleFactory()  # type: ignore[assignment]
    schedule.refresh_from_db()
    assert schedule.status == RentScheduleStatus.PENDING


def test_schedule_money_is_decimal() -> None:
    schedule: RentSchedule = RentScheduleFactory(amount=Decimal("20000.00"))  # type: ignore[assignment]
    schedule.refresh_from_db()
    assert schedule.amount == Decimal("20000.00")


def test_schedule_amount_field_is_decimal_field() -> None:
    amount_field = RentSchedule._meta.get_field("amount")
    assert isinstance(amount_field, models.DecimalField)
    assert amount_field.max_digits == 12
    assert amount_field.decimal_places == 2


def test_schedule_str() -> None:
    schedule: RentSchedule = RentScheduleFactory()  # type: ignore[assignment]
    assert f"lease {schedule.lease_id}" in str(schedule)
    assert "2026-01" in str(schedule)


def test_schedule_sent_at_defaults_none() -> None:
    schedule: RentSchedule = RentScheduleFactory()  # type: ignore[assignment]
    schedule.refresh_from_db()
    assert schedule.sent_at is None


def test_schedule_lease_fk_is_cascade() -> None:
    field = RentSchedule._meta.get_field("lease")
    assert isinstance(field, models.ForeignKey)
    assert field.remote_field.on_delete is models.CASCADE


def test_schedule_cascade_on_lease_hard_delete() -> None:
    """Hard-deleting a lease removes its rent schedule rows (CASCADE)."""
    schedule: RentSchedule = RentScheduleFactory()  # type: ignore[assignment]
    lease = schedule.lease
    schedule_pk = schedule.pk
    lease.hard_delete()
    assert RentSchedule.objects.filter(pk=schedule_pk).count() == 0


def test_schedule_unique_lease_period() -> None:
    """Cannot create two schedule rows for the same lease + period."""
    schedule: RentSchedule = RentScheduleFactory(period="2026-03")  # type: ignore[assignment]
    with pytest.raises(IntegrityError):
        RentScheduleFactory(  # type: ignore[call-arg]
            lease=schedule.lease,
            period="2026-03",
            due_date=datetime.date(2026, 3, 5),
        )


# --- RentScheduleStatus matches enums.md ------------------------------------


def test_rent_schedule_status_values_match_spec() -> None:
    assert set(RentScheduleStatus.values) == {
        "pending",
        "requested",
        "paid",
        "overdue",
    }


# --- RentSchedule indexes ---------------------------------------------------


def test_schedule_indexes_include_lease_status() -> None:
    index_field_sets = {tuple(idx.fields) for idx in RentSchedule._meta.indexes}
    assert ("lease", "status") in index_field_sets
