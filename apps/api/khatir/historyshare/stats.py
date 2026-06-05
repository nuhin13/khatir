"""Factual rental-history stats — pure computation over EPIC-07 / EPIC-04 data.

:func:`compute_factual_stats` is a **pure function**: given a tenant it reads the
tenant's ``Payment`` / ``RentRequest`` / ``RentSchedule`` / ``Lease`` rows and
returns three FACTUAL measures. It performs **no writes** and exposes **no
subjective field** — no rating, no score, no opinion. The result is meant to be
snapshotted onto a :class:`~khatir.historyshare.models.HistoryShare` at share
time so a recipient sees a frozen, factual record.

The three measures:

* ``on_time_payment_count`` — verified payments whose verification happened on or
  before the schedule's ``due_date`` (one-off requests with no schedule are not
  counted as on-time because there is no due date to compare against).
* ``total_payments`` — count of verified ``Payment`` rows for the tenant.
* ``lease_completed`` — whether the tenant has at least one lease that reached an
  ``ended`` status (i.e. completed its term).
"""

from __future__ import annotations

import datetime
from typing import TYPE_CHECKING, TypedDict

from django.db.models import Q
from django.utils import timezone

from khatir.leases.enums import LeaseStatus
from khatir.leases.models import Lease
from khatir.rent.models import Payment

if TYPE_CHECKING:
    from khatir.tenants.models import Tenant


class FactualStats(TypedDict):
    """The factual, subjective-free shape stored on a share and returned to a recipient."""

    on_time_payment_count: int
    total_payments: int
    lease_completed: bool


def _is_on_time(verified_at: datetime.datetime, due_date: datetime.date) -> bool:
    """A payment is on time if verified on or before the end of its due date."""
    verified_date = timezone.localdate(verified_at)
    return verified_date <= due_date


def compute_factual_stats(tenant: Tenant) -> FactualStats:
    """Compute FACTUAL stats for ``tenant`` from EPIC-07 / EPIC-04 data.

    Pure read — no writes, no subjective data.
    """
    payments = (
        Payment.objects.filter(
            rent_request__lease__tenant=tenant,
            verified_at__isnull=False,
        )
        .select_related("rent_request", "rent_request__rent_schedule")
    )

    total_payments = 0
    on_time_payment_count = 0
    for payment in payments:
        total_payments += 1
        schedule = payment.rent_request.rent_schedule
        if schedule is not None and _is_on_time(payment.verified_at, schedule.due_date):
            on_time_payment_count += 1

    lease_completed = Lease.objects.filter(
        Q(tenant=tenant) & Q(status=LeaseStatus.ENDED)
    ).exists()

    return FactualStats(
        on_time_payment_count=on_time_payment_count,
        total_payments=total_payments,
        lease_completed=lease_completed,
    )
