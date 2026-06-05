"""Row-level isolation for the gatekeeper domain (``04_coding_conventions.md`` §3).

Every view that touches ``CaretakerAssignment``/``VisitorEntry`` data scopes its
queryset through ``for_user()`` — never ``.objects.all()``. A missing scope is a
P0 security bug.

Scoping rules
-------------
- **Caretaker** sees only the buildings they are actively assigned to, and the
  visitor entries logged against those buildings.
- **Landlord / Manager** see assignments and visitor entries for the buildings
  they can see through ``Building.objects.for_user`` (they own / manage them).
- **Everyone else** (tenant / admin / anonymous) gets an empty queryset.
"""

from __future__ import annotations

from typing import Any

from django.db import models

from khatir.core.enums import Role


def _active_assigned_building_ids(user: Any) -> models.QuerySet[Any]:
    """Primary keys of buildings the caretaker is *actively* assigned to."""
    from .enums import CaretakerAssignmentStatus
    from .models import CaretakerAssignment

    return (
        CaretakerAssignment.objects.filter(
            caretaker=user, status=CaretakerAssignmentStatus.ACTIVE
        )
        .values("building_id")
        .distinct()
    )


def _visible_building_ids(user: Any) -> models.QuerySet[Any]:
    """Primary keys of buildings the owner/manager can see via properties scoping."""
    from khatir.properties.models import Building

    return Building.objects.for_user(user).values("pk")


class CaretakerAssignmentQuerySet(models.QuerySet["CaretakerAssignment"]):
    """Adds ``for_user`` row-level scoping."""

    def for_user(self, user: Any) -> CaretakerAssignmentQuerySet:
        if not (user and getattr(user, "is_authenticated", False)):
            return self.none()
        role = getattr(user, "role", None)
        if role == Role.CARETAKER:
            return self.filter(caretaker=user)
        if role in (Role.LANDLORD, Role.MANAGER):
            return self.filter(building_id__in=models.Subquery(_visible_building_ids(user)))
        return self.none()


class CaretakerAssignmentManager(models.Manager["CaretakerAssignment"]):
    """Default manager exposing ``for_user``."""

    def get_queryset(self) -> CaretakerAssignmentQuerySet:
        return CaretakerAssignmentQuerySet(self.model, using=self._db)

    def for_user(self, user: Any) -> CaretakerAssignmentQuerySet:
        return self.get_queryset().for_user(user)


class VisitorEntryQuerySet(models.QuerySet["VisitorEntry"]):
    """Adds ``for_user`` row-level scoping."""

    def for_user(self, user: Any) -> VisitorEntryQuerySet:
        if not (user and getattr(user, "is_authenticated", False)):
            return self.none()
        role = getattr(user, "role", None)
        if role == Role.CARETAKER:
            return self.filter(
                building_id__in=models.Subquery(_active_assigned_building_ids(user))
            )
        if role in (Role.LANDLORD, Role.MANAGER):
            return self.filter(building_id__in=models.Subquery(_visible_building_ids(user)))
        return self.none()


class VisitorEntryManager(models.Manager["VisitorEntry"]):
    """Default manager exposing ``for_user``."""

    def get_queryset(self) -> VisitorEntryQuerySet:
        return VisitorEntryQuerySet(self.model, using=self._db)

    def for_user(self, user: Any) -> VisitorEntryQuerySet:
        return self.get_queryset().for_user(user)
