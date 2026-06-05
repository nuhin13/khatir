"""Tests for :func:`compute_factual_stats` (T-001 §12).

Verifies the pure factual computation over EPIC-07 (rent) and EPIC-04 (lease)
data, and that the returned shape contains ONLY factual counts/booleans.
"""

from __future__ import annotations

import datetime

import pytest
from django.utils import timezone

from khatir.historyshare.stats import compute_factual_stats
from khatir.leases.enums import LeaseStatus, RentScheduleStatus
from khatir.leases.tests.factories import LeaseFactory, RentScheduleFactory
from khatir.rent.tests.factories import PaymentFactory, RentRequestFactory
from khatir.tenants.tests.factories import TenantFactory

pytestmark = pytest.mark.django_db


def _dt(year: int, month: int, day: int) -> datetime.datetime:
    return timezone.make_aware(datetime.datetime(year, month, day, 12, 0))


def test_empty_tenant_has_zero_stats() -> None:
    tenant = TenantFactory()
    stats = compute_factual_stats(tenant)
    assert stats == {
        "on_time_payment_count": 0,
        "total_payments": 0,
        "lease_completed": False,
    }


def test_total_payments_counts_only_verified() -> None:
    tenant = TenantFactory()
    lease = LeaseFactory(tenant=tenant)
    # Two verified payments.
    PaymentFactory(
        rent_request=RentRequestFactory(lease=lease), verified_at=_dt(2026, 1, 5)
    )
    PaymentFactory(
        rent_request=RentRequestFactory(lease=lease), verified_at=_dt(2026, 2, 5)
    )
    # One un-verified payment (verified_at None) — must NOT count.
    PaymentFactory(rent_request=RentRequestFactory(lease=lease), verified_at=None)

    stats = compute_factual_stats(tenant)
    assert stats["total_payments"] == 2


def test_on_time_uses_schedule_due_date() -> None:
    tenant = TenantFactory()
    lease = LeaseFactory(tenant=tenant)
    schedule = RentScheduleFactory(
        lease=lease,
        period="2026-01",
        due_date=datetime.date(2026, 1, 5),
        status=RentScheduleStatus.PAID,
    )
    # On time: verified on the due date.
    PaymentFactory(
        rent_request=RentRequestFactory(lease=lease, rent_schedule=schedule),
        verified_at=_dt(2026, 1, 5),
    )
    # Late: verified after the due date.
    schedule_late = RentScheduleFactory(
        lease=lease,
        period="2026-02",
        due_date=datetime.date(2026, 2, 5),
    )
    PaymentFactory(
        rent_request=RentRequestFactory(lease=lease, rent_schedule=schedule_late),
        verified_at=_dt(2026, 2, 10),
    )

    stats = compute_factual_stats(tenant)
    assert stats["total_payments"] == 2
    assert stats["on_time_payment_count"] == 1


def test_payment_without_schedule_not_counted_on_time() -> None:
    tenant = TenantFactory()
    lease = LeaseFactory(tenant=tenant)
    PaymentFactory(
        rent_request=RentRequestFactory(lease=lease, rent_schedule=None),
        verified_at=_dt(2026, 1, 1),
    )
    stats = compute_factual_stats(tenant)
    assert stats["total_payments"] == 1
    assert stats["on_time_payment_count"] == 0


def test_lease_completed_true_when_a_lease_ended() -> None:
    tenant = TenantFactory()
    LeaseFactory(tenant=tenant, status=LeaseStatus.ENDED)
    stats = compute_factual_stats(tenant)
    assert stats["lease_completed"] is True


def test_lease_completed_false_when_only_active() -> None:
    tenant = TenantFactory()
    LeaseFactory(tenant=tenant, status=LeaseStatus.ACTIVE)
    stats = compute_factual_stats(tenant)
    assert stats["lease_completed"] is False


def test_other_tenants_data_is_isolated() -> None:
    tenant = TenantFactory()
    other = TenantFactory()
    other_lease = LeaseFactory(tenant=other, status=LeaseStatus.ENDED)
    PaymentFactory(
        rent_request=RentRequestFactory(lease=other_lease), verified_at=_dt(2026, 1, 5)
    )
    stats = compute_factual_stats(tenant)
    assert stats == {
        "on_time_payment_count": 0,
        "total_payments": 0,
        "lease_completed": False,
    }


def test_stats_shape_is_factual_only() -> None:
    tenant = TenantFactory()
    stats = compute_factual_stats(tenant)
    assert set(stats.keys()) == {
        "on_time_payment_count",
        "total_payments",
        "lease_completed",
    }
