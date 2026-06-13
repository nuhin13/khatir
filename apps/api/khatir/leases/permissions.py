"""Object-level ownership permission for the leases domain.

Named by intent (``04_coding_conventions.md`` §4); composes with ``&`` / ``|``
alongside the role classes in ``khatir.core.permissions``. This guards a *single*
lease once fetched — list scoping is the job of ``managers.for_user()`` (§3).
Together they form the two-layer isolation contract.

A manager's link set is read through the same ``_managed_owner_ids`` helper the
queryset uses, so list and object checks agree on who a manager may act for.
"""

from __future__ import annotations

from typing import Any

from rest_framework.permissions import BasePermission
from rest_framework.request import Request

from khatir.core.enums import Role
from khatir.properties.managers import _managed_owner_ids


def _owns_lease(user: Any, landlord_id: Any) -> bool:
    """Whether ``user`` may act on a lease whose landlord is ``landlord_id``."""
    if not (user and getattr(user, "is_authenticated", False)):
        return False
    role = getattr(user, "role", None)
    if role == Role.LANDLORD:
        return bool(landlord_id == user.pk)
    if role == Role.MANAGER:
        return landlord_id in set(_managed_owner_ids(user))
    return False


class IsOwnerOfLease(BasePermission):
    """Object permission: the lease's landlord is (or is managed by) the user.

    Expects the object to be a ``Lease`` (has a ``landlord_id``).
    """

    def has_object_permission(self, request: Request, view: Any, obj: Any) -> bool:
        return _owns_lease(request.user, getattr(obj, "landlord_id", None))
