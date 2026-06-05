"""factory-boy factories for the reviews domain.

factory-boy ships no type stubs, so its dynamic attributes (``SubFactory``,
``Iterator``) are opaque to mypy; the per-module override in ``pyproject.toml``
relaxes the strict untyped-call checks here.
"""

from __future__ import annotations

import factory

from khatir.accounts.tests.factories import UserFactory
from khatir.leases.tests.factories import LeaseFactory
from khatir.reviews.enums import ReviewVisibility
from khatir.reviews.models import Review


class ReviewFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = Review

    lease = factory.SubFactory(LeaseFactory)  # type: ignore[attr-defined]
    reviewer = factory.SubFactory(UserFactory)  # type: ignore[attr-defined]
    reviewee = factory.SubFactory(UserFactory)  # type: ignore[attr-defined]
    rating = 5
    comment = "Great to work with."
    visibility = ReviewVisibility.PRIVATE
