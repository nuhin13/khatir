"""Object-level ownership permissions for the properties domain.

Named by intent (``04_coding_conventions.md`` §4); compose with ``&`` / ``|``
alongside the role classes in ``khatir.core.permissions``. These guard a *single*
object once it has been fetched — list scoping is the job of
``managers.for_user()`` (§3). Together they form the two-layer isolation
contract: ``for_user`` keeps an object out of a user's list, and the object
permission keeps it out of their detail/write endpoints.

A manager's link set is read through ``user.managed_owner_ids()`` (the same
helper the queryset uses), so list and object checks agree on who a manager may
see.
"""

from __future__ import annotations

from typing import Any

from rest_framework.permissions import BasePermission
from rest_framework.request import Request

from khatir.core.enums import Role

from .managers import _managed_owner_ids


def _owns_building(user: Any, owner_id: Any) -> bool:
    """Whether ``user`` may act on a building owned by ``owner_id``."""
    if not (user and getattr(user, "is_authenticated", False)):
        return False
    role = getattr(user, "role", None)
    if role == Role.LANDLORD:
        return bool(owner_id == user.pk)
    if role == Role.MANAGER:
        return owner_id in set(_managed_owner_ids(user))
    return False


class IsOwnerOfBuilding(BasePermission):
    """Object permission: the building is owned by (or managed for) the user.

    Expects the object to be a ``Building`` (has an ``owner_id``).
    """

    def has_object_permission(self, request: Request, view: Any, obj: Any) -> bool:
        return _owns_building(request.user, getattr(obj, "owner_id", None))


class IsOwnerOfUnit(BasePermission):
    """Object permission: the unit's building is owned by (or managed for) the user.

    Expects the object to be a ``Unit`` (reachable via ``building.owner_id``).
    """

    def has_object_permission(self, request: Request, view: Any, obj: Any) -> bool:
        building = getattr(obj, "building", None)
        owner_id = getattr(building, "owner_id", None)
        return _owns_building(request.user, owner_id)
