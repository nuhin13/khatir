"""factory-boy factories for the admin_portal domain.

factory-boy ships no type stubs, so its dynamic attributes are opaque to mypy;
the per-module override in ``pyproject.toml`` relaxes the untyped-call checks.
"""

from __future__ import annotations

import factory
from django.contrib.auth.hashers import make_password

from khatir.admin_portal.models import AdminAuditEntry, AdminUser
from khatir.core.enums import AdminRole


class AdminUserFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = AdminUser

    email = factory.Sequence(lambda n: f"admin{n}@khatir.io")  # type: ignore[attr-defined]
    name = factory.Sequence(lambda n: f"Admin User {n}")  # type: ignore[attr-defined]
    password_hash = factory.LazyFunction(lambda: make_password("testpassword123"))  # type: ignore[attr-defined]
    role = AdminRole.OPS
    scope = factory.LazyFunction(dict)  # type: ignore[attr-defined]
    disabled = False


class AdminAuditEntryFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = AdminAuditEntry

    admin_user = factory.SubFactory(AdminUserFactory)  # type: ignore[attr-defined]
    action = factory.Sequence(lambda n: f"admin_user.action_{n}")  # type: ignore[attr-defined]
    entity_type = ""
    entity_id = ""
    before_json = None
    after_json = None
    ip = "203.0.113.7"
    reason = ""
