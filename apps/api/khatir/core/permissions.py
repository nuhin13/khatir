"""Base permission classes + the ``for_user`` scoping pattern.

Domain apps subclass these and add intent-named permissions in their own
``permissions.py`` (``04_coding_conventions.md`` §4). Compose with ``&`` / ``|``;
never inline permission logic in a view body.

Role gating (``04_coding_conventions.md`` §4)
---------------------------------------------
Gate endpoints with the role permission classes below — never write
``if request.user.role == ...`` inside a view. Role is read from
``request.user.role`` (the DB truth), not the token claim, so a role switch
takes effect immediately and there are no stale-role bugs.

The single-role classes (:class:`IsLandlord`, :class:`IsManager`,
:class:`IsTenant`, :class:`IsAdminRole`) and the multi-role helpers
(:class:`IsLandlordOrManager`, the :func:`HasRole` factory) all combine with
DRF's ``&`` (AND) / ``|`` (OR) operators::

    from khatir.core.permissions import (
        HasRole, IsLandlord, IsLandlordOrManager, IsManager,
    )
    from khatir.core.enums import Role

    class BuildingViewSet(ModelViewSet):
        # landlords OR managers may reach this endpoint
        permission_classes = [IsLandlordOrManager]

    class PayoutViewSet(ModelViewSet):
        # equivalent, spelled with the explicit factory
        permission_classes = [HasRole(Role.LANDLORD, Role.MANAGER)]

    class ReportView(APIView):
        # AND-compose role gating with object/feature checks
        permission_classes = [IsLandlord & SomeOtherPermission]

The factory and the composed classes are interchangeable; pick whichever reads
clearest at the call site.

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


class RoleBasedPermission(BasePermission):
    """Base for role checks. Subclasses set ``required_roles``.

    An empty ``required_roles`` means "any authenticated user" — the class then
    behaves like :class:`IsAuthenticated`. Role is read from ``request.user.role``
    (DB truth), never the token claim, so a role switch is effective immediately.
    """

    required_roles: tuple[str, ...] = ()

    def has_permission(self, request: Request, view: Any) -> bool:
        user = request.user
        if not (user and user.is_authenticated):
            return False
        if not self.required_roles:
            return True
        return getattr(user, "role", None) in self.required_roles


def HasRole(*roles: str) -> type[RoleBasedPermission]:  # noqa: N802 - DRF classes are CapWords
    """Factory returning a permission class that allows any of ``roles``.

    Use when no named class exists for the combination you need::

        permission_classes = [HasRole(Role.LANDLORD, Role.MANAGER)]

    The returned class composes with ``&`` / ``|`` like any other permission.
    """
    allowed = tuple(roles)
    label = "_".join(str(r) for r in allowed) or "Any"

    class _HasRole(RoleBasedPermission):
        required_roles = allowed

    _HasRole.__name__ = f"HasRole_{label}"
    _HasRole.__qualname__ = _HasRole.__name__
    return _HasRole


class IsLandlord(RoleBasedPermission):
    required_roles = (Role.LANDLORD,)


class IsManager(RoleBasedPermission):
    required_roles = (Role.MANAGER,)


class IsTenant(RoleBasedPermission):
    required_roles = (Role.TENANT,)


class IsAdminRole(RoleBasedPermission):
    required_roles = (Role.ADMIN,)


class IsLandlordOrManager(RoleBasedPermission):
    required_roles = (Role.LANDLORD, Role.MANAGER)


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
