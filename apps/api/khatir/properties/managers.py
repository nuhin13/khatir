"""Row-level isolation for the properties domain (``04_coding_conventions.md`` §3).

Every view that touches ``Building``/``Unit`` data scopes its queryset through
``for_user()`` — never ``.objects.all()``. A missing scope is a P0 security bug.

Scoping rules
-------------
- **Landlord** sees only buildings they own (``owner == user``).
- **Manager** sees buildings of the owners they are linked to, via
  ``ManagerOwnerLink`` (wired in EPIC-01, fully used in EPIC-22). The set of
  linked owner ids is read through the ``user.managed_owner_ids()`` helper; when
  a manager has no links (or the helper is not yet wired) the manager sees
  nothing.
- **Everyone else** (tenant / caretaker / admin / anonymous) gets an empty
  queryset — they do not list properties through this manager.

``Unit`` scopes via its parent building: a unit is visible iff its building is
visible to the user.
"""

from __future__ import annotations

from collections.abc import Iterable
from typing import Any

from django.db import models

from khatir.core.enums import Role
from khatir.core.models import SoftDeleteManager, SoftDeleteQuerySet


def _managed_owner_ids(user: Any) -> Iterable[Any]:
    """Owner ids a manager is linked to.

    Prefers the ``user.managed_owner_ids()`` helper (the documented contract).
    Falls back to an empty list when the helper is not yet wired (the
    ``ManagerOwnerLink`` table is wired in EPIC-01 and only fully populated in
    EPIC-22), so an unlinked manager safely sees nothing rather than erroring.
    """
    helper = getattr(user, "managed_owner_ids", None)
    if callable(helper):
        result: Iterable[Any] = helper()
        return result
    return ()


class BuildingQuerySet(SoftDeleteQuerySet):
    """Adds ``for_user`` row-level scoping on top of soft-delete filtering."""

    def for_user(self, user: Any) -> BuildingQuerySet:
        if not (user and getattr(user, "is_authenticated", False)):
            return self.none()
        role = getattr(user, "role", None)
        if role == Role.LANDLORD:
            return self.filter(owner=user)
        if role == Role.MANAGER:
            return self.filter(owner_id__in=_managed_owner_ids(user))
        return self.none()


class BuildingManager(SoftDeleteManager):
    """Default manager: hides soft-deleted rows and exposes ``for_user``."""

    def get_queryset(self) -> BuildingQuerySet:
        return BuildingQuerySet(self.model, using=self._db).filter(deleted_at__isnull=True)

    def for_user(self, user: Any) -> BuildingQuerySet:
        return self.get_queryset().for_user(user)


class UnitQuerySet(SoftDeleteQuerySet):
    """Scopes units through their parent building's ``for_user`` visibility."""

    def for_user(self, user: Any) -> UnitQuerySet:
        # Import locally to avoid a circular import at module load.
        from .models import Building

        visible_buildings = Building.objects.for_user(user)
        return self.filter(building__in=models.Subquery(visible_buildings.values("pk")))


class UnitManager(SoftDeleteManager):
    """Default manager: hides soft-deleted rows and exposes ``for_user``."""

    def get_queryset(self) -> UnitQuerySet:
        return UnitQuerySet(self.model, using=self._db).filter(deleted_at__isnull=True)

    def for_user(self, user: Any) -> UnitQuerySet:
        return self.get_queryset().for_user(user)
