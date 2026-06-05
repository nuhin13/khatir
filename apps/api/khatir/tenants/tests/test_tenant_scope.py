"""Tenant-account resolution + strict tenant-scoping tests (EPIC-19 · T-001).

Covers the two-layer isolation contract for the tenant role: the
``tenant_for_user`` resolver, the row-level scoping helpers, and the
``IsLinkedTenant`` permission. The load-bearing assertion is that a tenant can
reach **only** their own lease — a second tenant's lease is invisible (empty
queryset / no resolution), never leaked.
"""

from __future__ import annotations

import datetime

import pytest

from khatir.accounts.enums import Role
from khatir.accounts.tests.factories import UserFactory
from khatir.leases.enums import LeaseStatus
from khatir.leases.tests.factories import LeaseFactory
from khatir.tenants.permissions import IsLinkedTenant
from khatir.tenants.tenant_account import (
    active_lease_for_user,
    leases_for_tenant_user,
    tenant_for_user,
    tenants_for_user,
)
from khatir.tenants.tests.factories import TenantFactory

pytestmark = pytest.mark.django_db


def _tenant_user():
    return UserFactory(role=Role.TENANT)


def test_tenant_resolves_own() -> None:
    user = _tenant_user()
    tenant = TenantFactory(linked_user=user)

    assert tenant_for_user(user) == tenant
    assert list(tenants_for_user(user)) == [tenant]


def test_unlinked_tenant_user_resolves_none() -> None:
    user = _tenant_user()
    TenantFactory()  # exists but linked to nobody

    assert tenant_for_user(user) is None
    assert list(tenants_for_user(user)) == []


def test_non_tenant_role_resolves_none() -> None:
    landlord = UserFactory(role=Role.LANDLORD)
    # even if a Tenant record were linked, a non-tenant role gets nothing
    TenantFactory(linked_user=landlord)

    assert tenant_for_user(landlord) is None
    assert list(tenants_for_user(landlord)) == []


def test_anonymous_resolves_none() -> None:
    class _Anon:
        is_authenticated = False
        role = None

    assert tenant_for_user(_Anon()) is None
    assert list(leases_for_tenant_user(_Anon())) == []


def test_cannot_see_others() -> None:
    """A tenant's scoping helpers never surface another tenant's lease."""
    me = _tenant_user()
    other = _tenant_user()
    my_tenant = TenantFactory(linked_user=me)
    other_tenant = TenantFactory(linked_user=other)

    my_lease = LeaseFactory(tenant=my_tenant, status=LeaseStatus.ACTIVE)
    other_lease = LeaseFactory(tenant=other_tenant, status=LeaseStatus.ACTIVE)

    my_leases = list(leases_for_tenant_user(me))
    assert my_lease in my_leases
    assert other_lease not in my_leases

    # the other tenant's lease is unreachable from my scope
    assert list(leases_for_tenant_user(other)) == [other_lease]


def test_active_lease_is_current_view() -> None:
    user = _tenant_user()
    tenant = TenantFactory(linked_user=user)
    LeaseFactory(
        tenant=tenant,
        status=LeaseStatus.ENDED,
        start_date=datetime.date(2024, 1, 1),
    )
    active = LeaseFactory(
        tenant=tenant,
        status=LeaseStatus.ACTIVE,
        start_date=datetime.date(2026, 1, 1),
    )

    assert active_lease_for_user(user) == active
    # but history (both leases) is still in the broader scope
    assert leases_for_tenant_user(user).count() == 2


def test_no_active_lease_returns_none() -> None:
    user = _tenant_user()
    tenant = TenantFactory(linked_user=user)
    LeaseFactory(tenant=tenant, status=LeaseStatus.ENDED)

    assert active_lease_for_user(user) is None


def test_is_linked_tenant_permission() -> None:
    linked = _tenant_user()
    TenantFactory(linked_user=linked)
    unlinked = _tenant_user()
    landlord = UserFactory(role=Role.LANDLORD)

    perm = IsLinkedTenant()

    class _Req:
        def __init__(self, u):
            self.user = u

    assert perm.has_permission(_Req(linked), view=None) is True
    assert perm.has_permission(_Req(unlinked), view=None) is False
    assert perm.has_permission(_Req(landlord), view=None) is False
