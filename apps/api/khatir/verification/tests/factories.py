"""factory-boy factories for the verification domain.

factory-boy ships no type stubs, so its dynamic attributes are opaque to mypy;
the per-module override in ``pyproject.toml`` relaxes the untyped-call checks.
"""

from __future__ import annotations

import factory

from khatir.accounts.tests.factories import UserFactory
from khatir.compliance.tests.factories import ConsentRecordFactory
from khatir.tenants.tests.factories import TenantFactory
from khatir.verification.enums import VerificationResult
from khatir.verification.models import VerificationLog


class VerificationLogFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = VerificationLog

    tenant = factory.SubFactory(TenantFactory)  # type: ignore[attr-defined]
    requested_by = factory.SubFactory(UserFactory)  # type: ignore[attr-defined]
    result = VerificationResult.MATCHED
    provider_ref = factory.Sequence(lambda n: f"ec-txn-{n:06d}")  # type: ignore[attr-defined]
    consent_record = factory.SubFactory(ConsentRecordFactory)  # type: ignore[attr-defined]
