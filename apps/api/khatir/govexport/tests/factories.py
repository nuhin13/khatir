"""factory-boy factories for the govexport domain.

factory-boy ships no type stubs, so its dynamic attributes are opaque to mypy;
the per-module override in ``pyproject.toml`` relaxes the untyped-call checks.
"""

from __future__ import annotations

import factory

from khatir.accounts.enums import Role
from khatir.accounts.tests.factories import UserFactory
from khatir.govexport.enums import GovExportStatus
from khatir.govexport.models import GovExport


class GovExportFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = GovExport

    landlord = factory.SubFactory(UserFactory, role=Role.LANDLORD)  # type: ignore[attr-defined]
    period = "2026-05"
    format_version = "2024-v1"
    file_ref = factory.Sequence(lambda n: f"govexport/export-{n:04d}.zip")  # type: ignore[attr-defined]
    record_count = 3
    status = GovExportStatus.GENERATED
