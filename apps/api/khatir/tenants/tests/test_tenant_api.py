"""API + scoping tests for the tenant CRUD endpoints (T-007 §12).

Exercises ``/api/v1/tenants`` (create / retrieve / update) and
``/api/v1/units/{id}/tenants`` through DRF's ``APIClient`` with a real
authenticated landlord. Covers NID encryption + masking on create, nested
family writes, the lease-based ``for_user`` scope, the cross-user **404**, and
that the full NID never appears in any API response (T-007 §14).
"""

from __future__ import annotations

import pytest
from rest_framework import status
from rest_framework.test import APIClient

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.core.models import AuditEntry
from khatir.leases.tests.factories import LeaseFactory
from khatir.properties.tests.factories import BuildingFactory, UnitFactory
from khatir.tenants.models import Tenant, TenantFamilyMember

pytestmark = pytest.mark.django_db

NID = "1990123456789"
MASKED = "*********6789"  # mask() shows the last 4 digits


@pytest.fixture
def landlord() -> User:
    created: User = UserFactory(  # type: ignore[assignment]
        phone="+8801712345678", name="Landlord", role=Role.LANDLORD
    )
    return created


@pytest.fixture
def client(landlord: User) -> APIClient:
    api = APIClient()
    api.force_authenticate(user=landlord)
    return api


def _lease_tenant_to(user: User, tenant: Tenant) -> None:
    """Give ``tenant`` a lease on a unit in a building ``user`` owns."""
    building = BuildingFactory(owner=user)
    unit = UnitFactory(building=building)
    LeaseFactory(unit=unit, tenant=tenant, landlord=user)


# --- create: encrypt + mask --------------------------------------------------


def test_create_encrypts_and_masks(client: APIClient, landlord: User) -> None:
    resp = client.post(
        "/api/v1/tenants",
        {"name": "Rahim", "nid_number": NID, "address": "Dhaka"},
        format="json",
    )

    assert resp.status_code == status.HTTP_201_CREATED
    body = resp.json()
    # Response never carries the full NID, only the masked form.
    assert body["nid_number_masked"] == MASKED
    assert NID not in resp.content.decode()
    assert "nid_number" not in body

    tenant = Tenant.objects.get(pk=body["id"])
    # The stored ciphertext is not the plaintext, but round-trips back to it.
    assert tenant.nid_number_enc is not None
    assert NID.encode() not in bytes(tenant.nid_number_enc)
    assert tenant.get_nid() == NID

    entry = AuditEntry.objects.get(action="tenant.create")
    assert entry.after is not None
    # Audit records only the masked NID, never the plaintext.
    assert NID not in str(entry.after)
    assert entry.after["nid_number_masked"] == MASKED


def test_create_with_nested_family(client: APIClient) -> None:
    resp = client.post(
        "/api/v1/tenants",
        {
            "name": "Karim",
            "nid_number": NID,
            "family_members": [
                {"name": "Fatima", "relation": "spouse"},
                {"name": "Ali", "relation": "child"},
            ],
        },
        format="json",
    )

    assert resp.status_code == status.HTTP_201_CREATED
    body = resp.json()
    assert TenantFamilyMember.objects.filter(tenant_id=body["id"]).count() == 2
    relations = {fm["relation"] for fm in body["family_members"]}
    assert relations == {"spouse", "child"}


# --- for_user scope ----------------------------------------------------------


def test_for_user_scope_via_lease(landlord: User) -> None:
    mine = Tenant.objects.create(name="Mine")
    _lease_tenant_to(landlord, mine)
    Tenant.objects.create(name="Leaseless")  # no lease → invisible
    other = Tenant.objects.create(name="Other")
    _lease_tenant_to(UserFactory(role=Role.LANDLORD), other)  # someone else's

    visible = list(Tenant.objects.for_user(landlord))

    assert visible == [mine]


def test_retrieve_own_tenant(client: APIClient, landlord: User) -> None:
    tenant = Tenant.objects.create(name="Mine")
    _lease_tenant_to(landlord, tenant)

    resp = client.get(f"/api/v1/tenants/{tenant.pk}")

    assert resp.status_code == status.HTTP_200_OK
    assert resp.json()["name"] == "Mine"


def test_cross_user_404(client: APIClient) -> None:
    other = Tenant.objects.create(name="NotYours")
    _lease_tenant_to(UserFactory(role=Role.LANDLORD), other)

    resp = client.get(f"/api/v1/tenants/{other.pk}")

    assert resp.status_code == status.HTTP_404_NOT_FOUND


def test_leaseless_tenant_is_404(client: APIClient) -> None:
    # A tenant with no lease is in nobody's scope, including its creator's.
    orphan = Tenant.objects.create(name="Orphan")

    resp = client.get(f"/api/v1/tenants/{orphan.pk}")

    assert resp.status_code == status.HTTP_404_NOT_FOUND


# --- unit tenants list -------------------------------------------------------


def test_unit_tenants_list(client: APIClient, landlord: User) -> None:
    building = BuildingFactory(owner=landlord)
    unit = UnitFactory(building=building)
    tenant = Tenant.objects.create(name="Renter")
    LeaseFactory(unit=unit, tenant=tenant, landlord=landlord)

    resp = client.get(f"/api/v1/units/{unit.pk}/tenants")

    assert resp.status_code == status.HTTP_200_OK
    names = [t["name"] for t in resp.json()]
    assert names == ["Renter"]


def test_unit_tenants_cross_user_empty(client: APIClient) -> None:
    other_owner = UserFactory(role=Role.LANDLORD)
    building = BuildingFactory(owner=other_owner)
    unit = UnitFactory(building=building)
    tenant = Tenant.objects.create(name="TheirRenter")
    LeaseFactory(unit=unit, tenant=tenant, landlord=other_owner)

    resp = client.get(f"/api/v1/units/{unit.pk}/tenants")

    assert resp.status_code == status.HTTP_200_OK
    assert resp.json() == []


# --- update ------------------------------------------------------------------


def test_update_tenant_and_family(client: APIClient, landlord: User) -> None:
    tenant = Tenant.objects.create(name="Old")
    _lease_tenant_to(landlord, tenant)

    resp = client.patch(
        f"/api/v1/tenants/{tenant.pk}",
        {
            "name": "New",
            "family_members": [{"name": "Sara", "relation": "spouse"}],
        },
        format="json",
    )

    assert resp.status_code == status.HTTP_200_OK
    tenant.refresh_from_db()
    assert tenant.name == "New"
    assert tenant.family_members.count() == 1
    assert AuditEntry.objects.filter(action="tenant.update").exists()


def test_update_changes_nid(client: APIClient, landlord: User) -> None:
    tenant = Tenant.objects.create(name="WithNid")
    tenant.set_nid("1111222233334")
    tenant.save()
    _lease_tenant_to(landlord, tenant)

    resp = client.patch(
        f"/api/v1/tenants/{tenant.pk}",
        {"nid_number": NID},
        format="json",
    )

    assert resp.status_code == status.HTTP_200_OK
    assert NID not in resp.content.decode()
    tenant.refresh_from_db()
    assert tenant.get_nid() == NID
    assert tenant.nid_number_masked == MASKED


def test_create_requires_role(landlord: User) -> None:
    tenant_user = UserFactory(role=Role.TENANT)
    api = APIClient()
    api.force_authenticate(user=tenant_user)

    resp = api.post("/api/v1/tenants", {"name": "X"}, format="json")

    assert resp.status_code == status.HTTP_403_FORBIDDEN
