"""factory-boy factories for the billing domain.

factory-boy ships no type stubs, so its dynamic attributes are opaque to mypy;
the per-module override in ``pyproject.toml`` relaxes the untyped-call checks.
"""

from __future__ import annotations

import factory

from khatir.billing.enums import BillingCycle, SubscriptionStatus
from khatir.billing.models import PricingTier, Subscription


class PricingTierFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = PricingTier

    key = factory.Sequence(lambda n: f"tier_{n}")  # type: ignore[attr-defined]
    label = factory.Sequence(lambda n: f"Tier {n}")  # type: ignore[attr-defined]
    label_bn = factory.Sequence(lambda n: f"টিয়ার {n}")  # type: ignore[attr-defined]
    tenant_min = 0
    tenant_max = None  # unlimited by default
    monthly_price = None
    annual_price = None
    includes_verification = False
    included_credits = 0
    active = True
    sort_order = factory.Sequence(lambda n: n)  # type: ignore[attr-defined]


class SubscriptionFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = Subscription

    user = factory.SubFactory(  # type: ignore[attr-defined]
        "khatir.accounts.tests.factories.UserFactory"
    )
    tier = factory.SubFactory(PricingTierFactory)  # type: ignore[attr-defined]
    billing_cycle = BillingCycle.MONTHLY
    status = SubscriptionStatus.ACTIVE
    start_at = factory.Faker("date_time_this_year", tzinfo=__import__("datetime").timezone.utc)  # type: ignore[attr-defined]
    next_billing_at = factory.Faker(  # type: ignore[attr-defined]
        "date_time_between",
        start_date="+1M",
        end_date="+2M",
        tzinfo=__import__("datetime").timezone.utc,
    )
