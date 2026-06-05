"""factory-boy factories for the warnings domain.

factory-boy ships no type stubs, so its dynamic attributes are opaque to mypy;
the per-module override in ``pyproject.toml`` relaxes the untyped-call checks.
"""

from __future__ import annotations

import factory

from khatir.accounts.tests.factories import UserFactory
from khatir.leases.tests.factories import LeaseFactory
from khatir.tenants.tests.factories import TenantFactory
from khatir.warnings.enums import WarningType
from khatir.warnings.models import Warning


class WarningFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = Warning

    lease = factory.SubFactory(LeaseFactory)  # type: ignore[attr-defined]
    tenant = factory.SubFactory(TenantFactory)  # type: ignore[attr-defined]
    landlord = factory.SubFactory(UserFactory)  # type: ignore[attr-defined]
    warning_type = WarningType.OTHER
    reason = factory.Sequence(lambda n: f"Warning reason {n}")  # type: ignore[attr-defined]
