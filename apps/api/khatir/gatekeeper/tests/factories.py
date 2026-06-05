"""factory-boy factories for the gatekeeper domain.

factory-boy ships no type stubs, so its dynamic attributes are opaque to mypy;
the per-module override in ``pyproject.toml`` relaxes the untyped-call checks.
"""

from __future__ import annotations

import factory

from khatir.accounts.enums import Role
from khatir.accounts.tests.factories import UserFactory
from khatir.gatekeeper.enums import CaretakerAssignmentStatus, VisitorEntryStatus
from khatir.gatekeeper.models import CaretakerAssignment, VisitorEntry
from khatir.properties.tests.factories import BuildingFactory


class CaretakerUserFactory(UserFactory):
    role = Role.CARETAKER


class CaretakerAssignmentFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = CaretakerAssignment

    caretaker = factory.SubFactory(CaretakerUserFactory)  # type: ignore[attr-defined]
    building = factory.SubFactory(BuildingFactory)  # type: ignore[attr-defined]
    assigned_by = factory.SubFactory(UserFactory)  # type: ignore[attr-defined]
    status = CaretakerAssignmentStatus.ACTIVE


class VisitorEntryFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = VisitorEntry

    building = factory.SubFactory(BuildingFactory)  # type: ignore[attr-defined]
    visitor_name = factory.Faker("name")  # type: ignore[attr-defined]
    purpose = "delivery"
    status = VisitorEntryStatus.PENDING
