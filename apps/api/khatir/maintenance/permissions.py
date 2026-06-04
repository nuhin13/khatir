"""Object-level ownership permission for the maintenance domain.

Named by intent (``04_coding_conventions.md`` §4); composes with ``&`` / ``|``
alongside the role classes in ``khatir.core.permissions``. This guards a *single*
maintenance request once fetched — list scoping is the job of
``MaintenanceRequestManager.for_user()`` (§3). Together they form the two-layer
isolation contract.

A request belongs to a user through its unit's building owner, so the object
check delegates to the same ``Unit.objects.for_user`` visibility the queryset
uses, keeping list and object checks in agreement.
"""

from __future__ import annotations

from typing import Any

from rest_framework.permissions import BasePermission
from rest_framework.request import Request


class IsOwnerOfMaintenanceRequest(BasePermission):
    """Object permission: the request's unit is visible to the user.

    Expects the object to be a ``MaintenanceRequest`` (has a ``unit_id``).
    """

    def has_object_permission(self, request: Request, view: Any, obj: Any) -> bool:
        user = request.user
        if not (user and getattr(user, "is_authenticated", False)):
            return False
        unit_id = getattr(obj, "unit_id", None)
        if unit_id is None:
            return False
        from khatir.properties.models import Unit

        return Unit.objects.for_user(user).filter(pk=unit_id).exists()  # type: ignore[attr-defined]


class IsOwnerOfExpense(BasePermission):
    """Object permission: the expense's unit is visible to the user.

    Expects the object to be an ``Expense`` (has a ``unit_id``). Mirrors
    :class:`IsOwnerOfMaintenanceRequest` — visibility derives from the unit's
    building owner via ``Unit.objects.for_user``, so list scoping and the object
    check agree and a foreign expense is a **404**.
    """

    def has_object_permission(self, request: Request, view: Any, obj: Any) -> bool:
        user = request.user
        if not (user and getattr(user, "is_authenticated", False)):
            return False
        unit_id = getattr(obj, "unit_id", None)
        if unit_id is None:
            return False
        from khatir.properties.models import Unit

        return Unit.objects.for_user(user).filter(pk=unit_id).exists()  # type: ignore[attr-defined]
