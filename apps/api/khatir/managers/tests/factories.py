"""factory-boy factories for the managers domain.

factory-boy ships no type stubs, so its dynamic attributes are opaque to mypy;
the per-module override in ``pyproject.toml`` relaxes the untyped-call checks.
"""

from __future__ import annotations

import factory

from khatir.accounts.enums import Role
from khatir.accounts.tests.factories import UserFactory
from khatir.managers.enums import ManagerOwnerLinkStatus
from khatir.managers.models import ManagerOwnerLink


class ManagerOwnerLinkFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = ManagerOwnerLink

    manager = factory.SubFactory(UserFactory, role=Role.MANAGER)  # type: ignore[attr-defined]
    owner = factory.SubFactory(UserFactory, role=Role.LANDLORD)  # type: ignore[attr-defined]
    status = ManagerOwnerLinkStatus.PENDING
