"""Row-level isolation for the leases domain (``04_coding_conventions.md`` §3).

Every view that touches ``Lease`` data scopes its queryset through
``for_user()`` — never ``.objects.all()``. A missing scope is a P0 security bug;
a foreign/unknown lease resolves to **404** (we never reveal it exists).

Scoping rules
-------------
- **Landlord** sees only leases where they are the ``landlord``.
- **Manager** sees leases of the owners they are linked to (the same
  ``managed_owner_ids`` set used for buildings/units, via
  ``khatir.properties.managers._managed_owner_ids``).
- **Everyone else** (tenant / admin / anonymous) gets an empty queryset.
"""

from __future__ import annotations

from typing import Any

from khatir.core.enums import Role
from khatir.core.models import SoftDeleteManager, SoftDeleteQuerySet
from khatir.properties.managers import _managed_owner_ids


class LeaseQuerySet(SoftDeleteQuerySet):
    """Adds ``for_user`` row-level scoping on top of soft-delete filtering."""

    def for_user(self, user: Any) -> LeaseQuerySet:
        if not (user and getattr(user, "is_authenticated", False)):
            return self.none()
        role = getattr(user, "role", None)
        if role == Role.LANDLORD:
            return self.filter(landlord=user)
        if role == Role.MANAGER:
            return self.filter(landlord_id__in=_managed_owner_ids(user))
        return self.none()


class LeaseManager(SoftDeleteManager):
    """Default manager: hides soft-deleted rows and exposes ``for_user``."""

    def get_queryset(self) -> LeaseQuerySet:
        return LeaseQuerySet(self.model, using=self._db).filter(
            deleted_at__isnull=True
        )

    def for_user(self, user: Any) -> LeaseQuerySet:
        return self.get_queryset().for_user(user)
