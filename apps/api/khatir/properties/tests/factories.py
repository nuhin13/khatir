"""factory-boy factories for the properties domain.

factory-boy ships no type stubs, so its dynamic attributes (``Sequence``,
``Faker``, ``SubFactory``) and the generated ``__call__`` are opaque to mypy;
the per-module override in ``pyproject.toml`` relaxes the strict untyped-call
checks here.
"""

from __future__ import annotations

from decimal import Decimal

import factory

from khatir.accounts.tests.factories import UserFactory
from khatir.properties.enums import Area, UnitStatus, UnitType
from khatir.properties.models import Building, Unit


class BuildingFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = Building

    owner = factory.SubFactory(UserFactory)  # type: ignore[attr-defined]
    name = factory.Sequence(lambda n: f"Building {n}")  # type: ignore[attr-defined]
    area = Area.UTTARA
    address = factory.Faker("address")  # type: ignore[attr-defined]


class UnitFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = Unit

    building = factory.SubFactory(BuildingFactory)  # type: ignore[attr-defined]
    label = factory.Sequence(lambda n: f"{n}A")  # type: ignore[attr-defined]
    type = UnitType.APARTMENT
    rent = Decimal("15000.00")
    status = UnitStatus.VACANT
    amenities = factory.LazyFunction(list)  # type: ignore[attr-defined]
