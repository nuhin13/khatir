"""factory-boy factories for the maintenance domain.

factory-boy ships no type stubs, so its dynamic attributes are opaque to mypy;
the per-module override in ``pyproject.toml`` relaxes the untyped-call checks.
"""

from __future__ import annotations

from decimal import Decimal

import factory

from khatir.maintenance.enums import (
    ExpenseCategory,
    ExpenseSource,
    MaintenanceCategory,
    MaintenanceStatus,
)
from khatir.maintenance.models import Expense, MaintenanceRequest
from khatir.properties.tests.factories import UnitFactory


class MaintenanceRequestFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = MaintenanceRequest

    unit = factory.SubFactory(UnitFactory)  # type: ignore[attr-defined]
    category = MaintenanceCategory.PLUMBING
    description = factory.Sequence(lambda n: f"Maintenance issue {n}")  # type: ignore[attr-defined]
    status = MaintenanceStatus.OPEN


class ExpenseFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = Expense

    unit = factory.SubFactory(UnitFactory)  # type: ignore[attr-defined]
    category = ExpenseCategory.PLUMBING
    amount = Decimal("5000.00")
    date = factory.Faker("date_object")  # type: ignore[attr-defined]
    source = ExpenseSource.MANUAL
    note = factory.Sequence(lambda n: f"Expense note {n}")  # type: ignore[attr-defined]
