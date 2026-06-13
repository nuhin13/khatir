"""Row-level isolation for the maintenance domain (``04_coding_conventions.md`` §3).

Every view that touches ``MaintenanceRequest`` data scopes its queryset through
``for_user()`` — never ``.objects.all()``. A missing scope is a P0 security bug;
a foreign/unknown request resolves to **404** (we never reveal it exists).

A maintenance request belongs to a user through its ``unit`` → ``building`` →
``owner`` chain, so visibility is delegated to the units the user can see
(``Unit.objects.for_user``). Landlords see requests on their own units; managers
see requests on the units of the owners they are linked to; everyone else sees
nothing.
"""

from __future__ import annotations

from typing import Any

from django.db import models

from khatir.core.models import SoftDeleteManager, SoftDeleteQuerySet


class MaintenanceRequestQuerySet(SoftDeleteQuerySet):
    """Adds ``for_user`` row-level scoping on top of soft-delete filtering."""

    def for_user(self, user: Any) -> MaintenanceRequestQuerySet:
        if not (user and getattr(user, "is_authenticated", False)):
            return self.none()
        # Import locally to avoid a circular import at module load.
        from khatir.properties.models import Unit

        visible_units = Unit.objects.for_user(user)
        return self.filter(
            unit__in=models.Subquery(visible_units.values("pk"))
        )


class MaintenanceRequestManager(SoftDeleteManager):
    """Default manager: hides soft-deleted rows and exposes ``for_user``."""

    def get_queryset(self) -> MaintenanceRequestQuerySet:
        return MaintenanceRequestQuerySet(self.model, using=self._db).filter(
            deleted_at__isnull=True
        )

    def for_user(self, user: Any) -> MaintenanceRequestQuerySet:
        return self.get_queryset().for_user(user)


class ExpenseQuerySet(SoftDeleteQuerySet):
    """Scopes expenses through their unit's parent-building visibility.

    An expense belongs to a unit, which belongs to a building owned by a
    landlord — so visibility mirrors the units the user can see
    (``Unit.objects.for_user``): landlords see expenses on their own units,
    managers see expenses on the units of the owners they are linked to, and
    everyone else sees nothing.
    """

    def for_user(self, user: Any) -> ExpenseQuerySet:
        if not (user and getattr(user, "is_authenticated", False)):
            return self.none()
        # Import locally to avoid a circular import at module load.
        from khatir.properties.models import Unit

        visible_units = Unit.objects.for_user(user)
        return self.filter(unit__in=models.Subquery(visible_units.values("pk")))


class ExpenseManager(SoftDeleteManager):
    """Default manager: hides soft-deleted rows and exposes ``for_user``."""

    def get_queryset(self) -> ExpenseQuerySet:
        return ExpenseQuerySet(self.model, using=self._db).filter(
            deleted_at__isnull=True
        )

    def for_user(self, user: Any) -> ExpenseQuerySet:
        return self.get_queryset().for_user(user)
