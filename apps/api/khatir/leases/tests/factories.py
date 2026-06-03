"""factory-boy factories for the leases domain.

factory-boy ships no type stubs, so its dynamic attributes (``Sequence``,
``Faker``, ``SubFactory``, ``LazyAttribute``) are opaque to mypy; the
per-module override in ``pyproject.toml`` relaxes the strict untyped-call
checks here.
"""

from __future__ import annotations

import datetime
from decimal import Decimal

import factory

from khatir.accounts.tests.factories import UserFactory
from khatir.leases.enums import LeaseStatus, RentScheduleStatus
from khatir.leases.models import Lease, RentSchedule
from khatir.properties.tests.factories import UnitFactory
from khatir.tenants.tests.factories import TenantFactory


class LeaseFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = Lease

    unit = factory.SubFactory(UnitFactory)  # type: ignore[attr-defined]
    tenant = factory.SubFactory(TenantFactory)  # type: ignore[attr-defined]
    landlord = factory.SubFactory(UserFactory)  # type: ignore[attr-defined]
    start_date = datetime.date(2026, 1, 1)
    end_date = datetime.date(2026, 12, 31)
    rent = Decimal("15000.00")
    advance = Decimal("30000.00")
    status = LeaseStatus.DRAFT


class RentScheduleFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = RentSchedule

    lease = factory.SubFactory(LeaseFactory)  # type: ignore[attr-defined]
    period = "2026-01"
    due_day = 5
    due_date = datetime.date(2026, 1, 5)
    amount = Decimal("15000.00")
    status = RentScheduleStatus.PENDING
