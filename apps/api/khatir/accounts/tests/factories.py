"""factory-boy factories for the accounts domain.

factory-boy ships no type stubs, so its dynamic attributes (``Sequence``,
``Faker``) and the generated ``__call__`` are opaque to mypy; the per-module
override in ``pyproject.toml`` relaxes the strict untyped-call checks here.
"""

from __future__ import annotations

import factory

from khatir.accounts.enums import Role
from khatir.accounts.models import User


class UserFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = User
        django_get_or_create = ("phone",)

    phone = factory.Sequence(lambda n: f"+88017{n:08d}")  # type: ignore[attr-defined]
    name = factory.Faker("name")  # type: ignore[attr-defined]
    role = Role.LANDLORD
