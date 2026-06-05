"""Tenant-account resolution + tenant-scoped read helpers (EPIC-19 · T-001).

A tenant-role :class:`~khatir.accounts.models.User` is linked to their identity
record through :attr:`Tenant.linked_user`. This module is the single source of
truth for turning that authenticated user back into the data they may read:

``tenant_for_user(user)``
    The :class:`Tenant` record bound to this user, or ``None``. A user is only
    ever linked to one identity record (``linked_user`` is a single FK on
    ``Tenant``), so the mapping is unambiguous.

``tenants_for_user`` / ``leases_for_tenant_user`` / ``active_lease_for_user``
    Row-level scoping helpers used by the ``/api/v1/me/`` endpoints (T-002+).
    They enforce the isolation contract of ``04_coding_conventions.md`` §3:
    a tenant sees only leases where they are the tenant, and nothing else
    resolves to anything but an **empty** queryset / ``None`` (never a foreign
    row — a missing scope is a P0 security bug).

Per the task notes, a tenant may have held several leases over time; the
*current view* is the single ``active`` lease, but the scoping helpers expose
every lease they hold so receipts/history remain reachable.
"""

from __future__ import annotations

from typing import Any

from khatir.core.enums import Role
from khatir.leases.enums import LeaseStatus
from khatir.leases.models import Lease
from khatir.tenants.models import Tenant


def _is_tenant_user(user: Any) -> bool:
    """Whether ``user`` is an authenticated tenant-role account."""
    if not (user and getattr(user, "is_authenticated", False)):
        return False
    return getattr(user, "role", None) == Role.TENANT


def tenant_for_user(user: Any) -> Tenant | None:
    """Resolve the :class:`Tenant` identity record linked to ``user``.

    Returns ``None`` for anonymous users, non-tenant roles, or a tenant user
    with no linked identity record. ``linked_user`` is a single FK, so at most
    one record matches.
    """
    if not _is_tenant_user(user):
        return None
    return Tenant.objects.filter(linked_user=user).first()


def tenants_for_user(user: Any) -> Any:
    """Scoped ``Tenant`` queryset: the caller's own record, or empty.

    Mirrors the ``for_user`` row-level isolation contract for the tenant role.
    """
    if not _is_tenant_user(user):
        return Tenant.objects.none()
    return Tenant.objects.filter(linked_user=user)


def leases_for_tenant_user(user: Any) -> Any:
    """Scoped ``Lease`` queryset: every lease this tenant holds (or held).

    Empty for non-tenant / unlinked users. Used by ``/me/lease`` history,
    ``/me/rent`` and ``/me/receipts`` so a tenant reaches only their own rows.
    """
    tenant = tenant_for_user(user)
    if tenant is None:
        return Lease.objects.none()
    return Lease.objects.filter(tenant=tenant)


def active_lease_for_user(user: Any) -> Lease | None:
    """The tenant's current (``active``) lease — the home/lease-view default.

    Returns the most recent active lease, or ``None`` when the tenant has no
    active lease (e.g. only ended/terminated history).
    """
    return (
        leases_for_tenant_user(user)
        .filter(status=LeaseStatus.ACTIVE)
        .order_by("-start_date", "-created_at")
        .first()
    )
