"""factory-boy factories for the compliance domain.

factory-boy ships no type stubs, so its dynamic attributes are opaque to mypy;
the per-module override in ``pyproject.toml`` relaxes the untyped-call checks.
"""

from __future__ import annotations

import factory

from khatir.accounts.tests.factories import UserFactory
from khatir.compliance.enums import ConsentType, DataRequestStatus, DataRequestType
from khatir.compliance.models import ConsentRecord, DataRequest


class ConsentRecordFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = ConsentRecord

    user = factory.SubFactory(UserFactory)  # type: ignore[attr-defined]
    consent_type = ConsentType.PDPA_DATA_COLLECTION


class DataRequestFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = DataRequest

    user = factory.SubFactory(UserFactory)  # type: ignore[attr-defined]
    request_type = DataRequestType.EXPORT
    status = DataRequestStatus.PENDING
    sla_due = factory.Faker("future_date")  # type: ignore[attr-defined]
