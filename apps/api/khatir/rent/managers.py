"""Row-level isolation for the rent-collection domain (``04_coding_conventions.md`` §3).

A ``RentRequest`` belongs to a landlord through its ``lease`` (``lease.landlord``).
Every view that lists/fetches rent requests scopes its queryset through
``for_user()`` — never ``.objects.all()``. A missing scope is a P0 security bug,
and a foreign/unknown request resolves to **404** (never 403 — we do not reveal
that the request exists).

Scoping rules
-------------
- **Landlord** sees only requests on leases they own (``lease.landlord == user``).
- **Manager** sees requests on leases owned by the owners they are linked to,
  via ``user.managed_owner_ids()`` (wired in EPIC-01, fully used in EPIC-22).
  When a manager has no links (or the helper is not yet wired) they see nothing.
- **Everyone else** (tenant / caretaker / admin / anonymous) gets an empty
  queryset — they do not list rent requests through this manager. (Tenants reach
  a single request only via the signed web-link token, never this API.)
"""

from __future__ import annotations

from collections.abc import Iterable
from typing import TYPE_CHECKING, Any

from django.db import models

from khatir.core.enums import Role

if TYPE_CHECKING:
    from .models import RentRequest  # noqa: F401  (used in string forward-refs below)


def _managed_owner_ids(user: Any) -> Iterable[Any]:
    """Owner ids a manager is linked to.

    Prefers the ``user.managed_owner_ids()`` helper (the documented contract).
    Falls back to an empty tuple when the helper is not yet wired, so an
    unlinked manager safely sees nothing rather than erroring.
    """
    helper = getattr(user, "managed_owner_ids", None)
    if callable(helper):
        result: Iterable[Any] = helper()
        return result
    return ()


class RentRequestQuerySet(models.QuerySet["RentRequest"]):
    """Adds ``for_user`` row-level scoping via the parent lease's landlord."""

    def for_user(self, user: Any) -> RentRequestQuerySet:
        if not (user and getattr(user, "is_authenticated", False)):
            return self.none()
        role = getattr(user, "role", None)
        if role == Role.LANDLORD:
            return self.filter(lease__landlord=user)
        if role == Role.MANAGER:
            return self.filter(lease__landlord_id__in=_managed_owner_ids(user))
        return self.none()


class RentRequestManager(models.Manager["RentRequest"]):
    """Default manager exposing ``for_user`` row-level scoping."""

    def get_queryset(self) -> RentRequestQuerySet:
        return RentRequestQuerySet(self.model, using=self._db)

    def for_user(self, user: Any) -> RentRequestQuerySet:
        return self.get_queryset().for_user(user)
