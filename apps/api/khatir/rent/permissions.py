"""Object-level ownership permission for the rent-collection domain.

Named by intent (``04_coding_conventions.md`` §4); compose with ``&`` / ``|``
alongside the role classes in ``khatir.core.permissions``. This guards a *single*
request once fetched — list scoping is the job of ``RentRequest.objects.for_user``
(§3). Together they form the two-layer isolation contract.
"""

from __future__ import annotations

from typing import Any

from rest_framework.permissions import BasePermission
from rest_framework.request import Request

from khatir.core.enums import Role


def _managed_owner_ids(user: Any) -> set[Any]:
    helper = getattr(user, "managed_owner_ids", None)
    return set(helper()) if callable(helper) else set()


class IsOwnerOfRentRequest(BasePermission):
    """Object permission: the request's lease is owned by (or managed for) the user.

    Expects the object to be a ``RentRequest`` (reachable via
    ``lease.landlord_id``).
    """

    def has_object_permission(self, request: Request, view: Any, obj: Any) -> bool:
        user = request.user
        if not (user and getattr(user, "is_authenticated", False)):
            return False
        landlord_id = getattr(getattr(obj, "lease", None), "landlord_id", None)
        role = getattr(user, "role", None)
        if role == Role.LANDLORD:
            return bool(landlord_id == user.pk)
        if role == Role.MANAGER:
            return landlord_id in _managed_owner_ids(user)
        return False
