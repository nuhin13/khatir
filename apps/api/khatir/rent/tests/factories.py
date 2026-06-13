"""factory-boy factories for the rent-collection domain.

factory-boy ships no type stubs, so its dynamic attributes (``Sequence``,
``Faker``, ``SubFactory``) are opaque to mypy; the per-module override in
``pyproject.toml`` relaxes the strict untyped-call checks here.
"""

from __future__ import annotations

from decimal import Decimal

import factory

from khatir.accounts.tests.factories import UserFactory
from khatir.leases.tests.factories import LeaseFactory
from khatir.rent.enums import Channel, PaymentProofType, RentRequestStatus
from khatir.rent.models import Payment, PaymentProof, RentRequest


class RentRequestFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = RentRequest

    lease = factory.SubFactory(LeaseFactory)  # type: ignore[attr-defined]
    rent_schedule = None
    amount = Decimal("15000.00")
    period = "2026-01"
    link_token = factory.Sequence(lambda n: f"tok_{n:08d}")  # type: ignore[attr-defined]
    sent_via = Channel.WHATSAPP
    status = RentRequestStatus.SENT


class PaymentProofFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = PaymentProof

    rent_request = factory.SubFactory(RentRequestFactory)  # type: ignore[attr-defined]
    type = PaymentProofType.BKASH_TXN
    value = "TXN1234567"
    photo_ref = ""


class PaymentFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = Payment

    rent_request = factory.SubFactory(RentRequestFactory)  # type: ignore[attr-defined]
    verified_by = factory.SubFactory(UserFactory)  # type: ignore[attr-defined]
    receipt_ref = ""
