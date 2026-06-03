"""factory-boy factories for the tenants domain.

factory-boy ships no type stubs, so its dynamic attributes are opaque to mypy;
the per-module override in ``pyproject.toml`` relaxes the untyped-call checks.
"""

from __future__ import annotations

import factory

from khatir.tenants.enums import VerificationStatus
from khatir.tenants.models import Tenant, TenantFamilyMember


class TenantFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = Tenant

    name = factory.Sequence(lambda n: f"Tenant {n}")  # type: ignore[attr-defined]
    nid_number_masked = factory.Sequence(lambda n: f"****{n:04d}")  # type: ignore[attr-defined]
    verification_status = VerificationStatus.UNVERIFIED


class TenantFamilyMemberFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = TenantFamilyMember

    tenant = factory.SubFactory(TenantFactory)  # type: ignore[attr-defined]
    name = factory.Sequence(lambda n: f"Relative {n}")  # type: ignore[attr-defined]
    relation = "spouse"
