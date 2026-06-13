"""Row-level isolation for the tenants domain (``04_coding_conventions.md`` §3).

A ``Tenant`` is an identity record with no direct owner column — a tenant is
reachable by a landlord/manager only through a **lease**: ``Tenant → Lease →
Unit → Building → owner`` (T-007 §15). ``for_user`` therefore scopes tenants to
those who hold a lease on a unit the user may see, reusing the properties
domain's own ``Unit.objects.for_user`` so the landlord/manager visibility rules
stay defined in exactly one place.

Every view that lists/fetches tenants scopes through ``for_user()`` — never
``.objects.all()``. A missing scope is a P0 security bug; an unknown/foreign
tenant id resolves to **404**, never 403.
"""

from __future__ import annotations

from typing import Any

from django.db import models

from khatir.core.models import SoftDeleteManager, SoftDeleteQuerySet


class TenantQuerySet(SoftDeleteQuerySet):
    """Adds ``for_user`` row-level scoping on top of soft-delete filtering."""

    def for_user(self, user: Any) -> TenantQuerySet:
        if not (user and getattr(user, "is_authenticated", False)):
            return self.none()  # type: ignore[return-value]

        # Import locally to avoid a circular import at module load and to keep
        # the leases dependency soft (a tenant with no lease is invisible here,
        # which matches the "tenant exists independent of a lease" schema rule).
        from khatir.properties.models import Unit

        visible_units = Unit.objects.for_user(user)
        return self.filter(
            leases__unit__in=models.Subquery(visible_units.values("pk"))
        ).distinct()


class TenantManager(SoftDeleteManager):
    """Default manager: hides soft-deleted rows and exposes ``for_user``."""

    def get_queryset(self) -> TenantQuerySet:
        return TenantQuerySet(self.model, using=self._db).filter(
            deleted_at__isnull=True
        )

    def for_user(self, user: Any) -> TenantQuerySet:
        return self.get_queryset().for_user(user)
