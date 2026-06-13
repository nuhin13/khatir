"""factory-boy factories for the leasedocs domain.

factory-boy ships no type stubs, so its dynamic attributes are opaque to mypy;
the per-module override in ``pyproject.toml`` relaxes the strict untyped-call
checks here.
"""

from __future__ import annotations

import factory

from khatir.accounts.tests.factories import UserFactory
from khatir.leasedocs.enums import LeaseDocumentStatus
from khatir.leasedocs.models import LeaseDocument
from khatir.leases.tests.factories import LeaseFactory


def _full_clauses() -> dict[str, str]:
    """A minimal but complete required-clause set."""
    return {
        "parties": "Landlord A and Tenant B.",
        "premises": "Flat 3B, House 12, Road 4, Dhaka.",
        "rent": "BDT 15,000 per month, due on the 5th.",
        "advance": "BDT 30,000 security deposit.",
        "term": "1 January 2026 to 31 December 2026.",
        "disclaimer": "This document is not legal advice.",
    }


class LeaseDocumentFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = LeaseDocument

    lease = factory.SubFactory(LeaseFactory)  # type: ignore[attr-defined]
    generated_by = factory.SubFactory(UserFactory)  # type: ignore[attr-defined]
    content_json = factory.LazyFunction(_full_clauses)  # type: ignore[attr-defined]
    model_used = "khatir-lease-v1"
    status = LeaseDocumentStatus.DRAFT
