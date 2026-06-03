"""factory-boy factories for the dmpforms domain.

factory-boy ships no type stubs, so its dynamic attributes are opaque to mypy;
the per-module override in ``pyproject.toml`` relaxes the untyped-call checks.
"""

from __future__ import annotations

import datetime

import factory

from khatir.accounts.tests.factories import UserFactory
from khatir.dmpforms.models import DMPFormRecord
from khatir.tenants.tests.factories import TenantFactory


class DMPFormRecordFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = DMPFormRecord

    tenant = factory.SubFactory(TenantFactory)  # type: ignore[attr-defined]
    template_version = "2024-v1"
    pdf_ref = factory.Sequence(lambda n: f"dmpforms/tenant-{n:04d}.pdf")  # type: ignore[attr-defined]
    generated_by = factory.SubFactory(UserFactory)  # type: ignore[attr-defined]
    generated_at = factory.LazyFunction(  # type: ignore[attr-defined]
        lambda: datetime.datetime(2026, 6, 1, 12, 0, 0, tzinfo=datetime.UTC)
    )
