"""Object-level permissions for the gatekeeper domain (``04_coding_conventions.md`` §4).

Assigning / revoking a caretaker is an **owner/manager** action on a building.
The reach gate (``IsLandlordOrManager``) keeps tenants/caretakers/anonymous off
the endpoint entirely; this object permission is the second layer that confirms
the acting user actually owns (or manages) the building in question. It reuses
the same ``_owns_building`` truth the properties domain uses, so the gatekeeper
and properties views agree on who may act on a building.

List scoping (which buildings a caller can even see) stays the job of
``managers.for_user()`` (§3) — a foreign/unknown building resolves to **404**,
never 403, so we never reveal that the building exists.
"""

from __future__ import annotations

from typing import Any

from rest_framework.permissions import BasePermission
from rest_framework.request import Request

from khatir.properties.permissions import _owns_building


class IsBuildingOwnerOrManager(BasePermission):
    """Object permission: the ``Building`` is owned by (or managed for) the user."""

    def has_object_permission(self, request: Request, view: Any, obj: Any) -> bool:
        return _owns_building(request.user, getattr(obj, "owner_id", None))
