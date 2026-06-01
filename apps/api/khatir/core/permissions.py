"""Base permission classes + the ``for_user`` scoping pattern.

Domain apps subclass these and add intent-named permissions in their own
``permissions.py`` (``04_coding_conventions.md`` §4). Compose with ``&`` / ``|``;
never inline permission logic in a view body.

Row-level isolation (``04_coding_conventions.md`` §3)
-----------------------------------------------------
Every domain model that belongs to a user is filtered through a ``for_user()``
manager method. Views never call ``.objects.all()`` on domain data. A missing
``for_user()`` scope is a P0 security bug. Tenants accessing data they do not own
get **404** (not 403 — do not reveal existence).

Pattern for domain apps::

    # managers.py
    class BuildingQuerySet(models.QuerySet):
        def for_user(self, user):
            if user.role == Role.LANDLORD:
                return self.filter(owner=user)
            if user.role == Role.MANAGER:
                return self.filter(owner__in=user.managed_owner_ids())
            return self.none()   # tenants don't list buildings

    class Building(SoftDeleteModel):
        objects = SoftDeleteManager.from_queryset(BuildingQuerySet)()

    # view
    buildings = Building.objects.for_user(request.user)

The mixin below provides the read side of that contract for generic viewsets.
"""

from __future__ import annotations

from typing import Any

from rest_framework.permissions import BasePermission
from rest_framework.request import Request

from .enums import Role


class IsAuthenticated(BasePermission):
    """Request user must be authenticated."""

    def has_permission(self, request: Request, view: Any) -> bool:
        return bool(request.user and request.user.is_authenticated)


class HasRole(BasePermission):
    """Base for role checks. Subclasses set ``required_role``."""

    required_role: str | None = None

    def has_permission(self, request: Request, view: Any) -> bool:
        user = request.user
        if not (user and user.is_authenticated):
            return False
        if self.required_role is None:
            return True
        return getattr(user, "role", None) == self.required_role


class IsLandlord(HasRole):
    required_role = Role.LANDLORD


class IsManager(HasRole):
    required_role = Role.MANAGER


class IsTenant(HasRole):
    required_role = Role.TENANT


class IsAdminRole(HasRole):
    required_role = Role.ADMIN


class ForUserQuerySetMixin:
    """Generic-view mixin that scopes the queryset via ``for_user()``.

    Drop into a DRF ``GenericAPIView``/``ViewSet`` whose model manager exposes a
    ``for_user(user)`` queryset method. Guarantees no view accidentally returns
    unscoped domain data.
    """

    queryset: Any = None

    def get_queryset(self) -> Any:
        qs = self.queryset
        if qs is None:  # pragma: no cover - misconfiguration guard
            raise AssertionError(
                f"{self.__class__.__name__} must set `queryset` to use ForUserQuerySetMixin."
            )
        manager_or_qs = qs.model._default_manager
        if not hasattr(manager_or_qs, "for_user"):  # pragma: no cover - contract guard
            raise AssertionError(
                f"{qs.model.__name__} manager must implement for_user() "
                "for row-level isolation (04_coding_conventions.md §3)."
            )
        return manager_or_qs.for_user(self.request.user)  # type: ignore[attr-defined]
