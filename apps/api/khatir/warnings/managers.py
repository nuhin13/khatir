"""Row-level isolation for the warnings domain (``04_coding_conventions.md`` §3).

A warning is *intrinsically private*: only the issuing landlord and that one
tenant relate to it. There is deliberately no aggregate/cross-landlord view.
Every view that touches ``Warning`` data scopes through ``for_user()`` — never
``.objects.all()``. A missing scope is a P0 security bug; a foreign/unknown
warning resolves to **404** (we never reveal it exists).

Scoping is by the issuing ``landlord``: a landlord sees only the warnings they
themselves issued; everyone else (including the tenant subject, who has no
landlord-side account here) sees nothing through this manager.
"""

from __future__ import annotations

from typing import Any

from khatir.core.models import SoftDeleteManager, SoftDeleteQuerySet


class WarningQuerySet(SoftDeleteQuerySet):
    """Adds ``for_user`` row-level scoping on top of soft-delete filtering."""

    def for_user(self, user: Any) -> WarningQuerySet:
        if not (user and getattr(user, "is_authenticated", False)):
            return self.none()
        return self.filter(landlord=user)


class WarningManager(SoftDeleteManager):
    """Default manager: hides soft-deleted rows and exposes ``for_user``."""

    def get_queryset(self) -> WarningQuerySet:
        return WarningQuerySet(self.model, using=self._db).filter(
            deleted_at__isnull=True
        )

    def for_user(self, user: Any) -> WarningQuerySet:
        return self.get_queryset().for_user(user)
