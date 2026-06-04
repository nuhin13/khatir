"""Object-level access permission for the tenants domain.

Two-layer isolation (``04_coding_conventions.md`` §3/§4): ``managers.for_user``
keeps a tenant out of a user's *lists*, and ``IsLeaseHolderForUser`` keeps a
single tenant out of their *detail/write* endpoints. A tenant is accessible iff
they hold a lease on a unit the user owns (landlord) or manages (manager) —
mirrored from the properties domain so the rules live in one place.
"""

from __future__ import annotations

from typing import Any

from rest_framework.permissions import BasePermission
from rest_framework.request import Request

from khatir.properties.permissions import _owns_building


class IsLeaseHolderForUser(BasePermission):
    """Object permission: the tenant has a lease on a unit the user may access.

    Expects the object to be a ``Tenant``. Walks ``tenant.leases →
    unit.building.owner_id`` and allows when any lease lands on a building the
    user owns/manages.
    """

    def has_object_permission(self, request: Request, view: Any, obj: Any) -> bool:
        owner_ids = (
            obj.leases.values_list("unit__building__owner_id", flat=True).distinct()
        )
        return any(_owns_building(request.user, owner_id) for owner_id in owner_ids)
