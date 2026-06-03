"""API tests for the buildings CRUD endpoints (T-003 §12).

Exercises ``/api/v1/buildings`` through DRF's ``APIClient`` with a real
authenticated landlord. Covers the CRUD happy paths, auth failure, validation
failure, the owner-is-server-set guarantee, audit writes, and — critically — the
cross-user **404** (other users' buildings are invisible, never 403, T-003 §15).
"""

from __future__ import annotations

import pytest
from rest_framework import status
from rest_framework.test import APIClient

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.core.models import AuditEntry
from khatir.properties.enums import Area
from khatir.properties.models import Building

from .factories import BuildingFactory

pytestmark = pytest.mark.django_db

BUILDINGS_URL = "/api/v1/buildings"


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


def _detail(pk: object) -> str:
    return f"{BUILDINGS_URL}/{pk}"


# ── create ──────────────────────────────────────────────────────────────────


def test_create_building(client: APIClient, landlord: User) -> None:
    body = {
        "name": "Karim Manzil",
        "area": Area.UTTARA.value,
        "address": "12 Road 3, Sector 4, Uttara",
        "lat": "23.873100",
        "lng": "90.379800",
    }

    resp = client.post(BUILDINGS_URL, body, format="json")

    assert resp.status_code == status.HTTP_201_CREATED
    assert resp.data["name"] == "Karim Manzil"
    assert resp.data["area"] == Area.UTTARA.value
    # Owner is set server-side from request.user, not the client.
    assert resp.data["owner_id"] == str(landlord.pk)
    building = Building.objects.get(pk=resp.data["id"])
    assert building.owner_id == landlord.pk


def test_create_ignores_client_supplied_owner(client: APIClient, landlord: User) -> None:
    other: User = UserFactory(phone="+8801799999999", role=Role.LANDLORD)  # type: ignore[assignment]

    resp = client.post(
        BUILDINGS_URL,
        {
            "owner_id": str(other.pk),
            "name": "Trust Nobody",
            "area": Area.MIRPUR.value,
            "address": "Mirpur 10",
        },
        format="json",
    )

    assert resp.status_code == status.HTTP_201_CREATED
    building = Building.objects.get(pk=resp.data["id"])
    assert building.owner_id == landlord.pk  # never the client-sent owner


def test_create_without_lat_lng(client: APIClient) -> None:
    resp = client.post(
        BUILDINGS_URL,
        {"name": "No Coords", "area": Area.DHANMONDI.value, "address": "Dhanmondi 27"},
        format="json",
    )

    assert resp.status_code == status.HTTP_201_CREATED
    assert resp.data["lat"] is None
    assert resp.data["lng"] is None


def test_create_writes_audit(client: APIClient, landlord: User) -> None:
    resp = client.post(
        BUILDINGS_URL,
        {"name": "Audited", "area": Area.GULSHAN.value, "address": "Gulshan 1"},
        format="json",
    )

    entry = AuditEntry.objects.get(action="building.create")
    assert entry.actor_id == landlord.pk
    assert entry.target_type == "properties.building"
    assert entry.target_id == str(resp.data["id"])
    assert entry.before is None
    assert entry.after["name"] == "Audited"


# ── create validation ─────────────────────────────────────────────────────────


def test_create_requires_address(client: APIClient) -> None:
    resp = client.post(
        BUILDINGS_URL,
        {"name": "No Address", "area": Area.BANANI.value},
        format="json",
    )

    assert resp.status_code == status.HTTP_400_BAD_REQUEST
    assert resp.data["error"]["code"] == "validation_error"
    assert "address" in resp.data["error"]["details"]


def test_create_rejects_invalid_area(client: APIClient) -> None:
    resp = client.post(
        BUILDINGS_URL,
        {"name": "Bad Area", "area": "narnia", "address": "Nowhere"},
        format="json",
    )

    assert resp.status_code == status.HTTP_400_BAD_REQUEST
    assert resp.data["error"]["code"] == "validation_error"
    assert "area" in resp.data["error"]["details"]


# ── auth ───────────────────────────────────────────────────────────────────


def test_list_requires_auth() -> None:
    resp = APIClient().get(BUILDINGS_URL)
    assert resp.status_code == status.HTTP_401_UNAUTHORIZED


def test_create_requires_auth() -> None:
    resp = APIClient().post(
        BUILDINGS_URL,
        {"name": "X", "area": Area.MIRPUR.value, "address": "Y"},
        format="json",
    )
    assert resp.status_code == status.HTTP_401_UNAUTHORIZED


def test_tenant_forbidden(landlord: User) -> None:
    tenant: User = UserFactory(phone="+8801700000001", role=Role.TENANT)  # type: ignore[assignment]
    api = APIClient()
    api.force_authenticate(user=tenant)

    resp = api.get(BUILDINGS_URL)

    assert resp.status_code == status.HTTP_403_FORBIDDEN
    assert resp.data["error"]["code"] == "permission_denied"


# ── list / retrieve (scoped) ──────────────────────────────────────────────────


def test_list_scoped_to_owner(client: APIClient, landlord: User) -> None:
    mine = BuildingFactory(owner=landlord)
    BuildingFactory()  # someone else's

    resp = client.get(BUILDINGS_URL)

    assert resp.status_code == status.HTTP_200_OK
    ids = [row["id"] for row in resp.data["results"]]
    assert ids == [str(mine.pk)]
    assert resp.data["pagination"]["count"] == 1


def test_retrieve_own_building(client: APIClient, landlord: User) -> None:
    building = BuildingFactory(owner=landlord)

    resp = client.get(_detail(building.pk))

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data["id"] == str(building.pk)


def test_retrieve_other_users_building_404(client: APIClient) -> None:
    other_building = BuildingFactory()  # belongs to a different landlord

    resp = client.get(_detail(other_building.pk))

    # 404, never 403 — we do not reveal that the building exists (T-003 §15).
    assert resp.status_code == status.HTTP_404_NOT_FOUND
    assert resp.data["error"]["code"] == "not_found"


# ── update ───────────────────────────────────────────────────────────────────


def test_update_building(client: APIClient, landlord: User) -> None:
    building = BuildingFactory(owner=landlord, name="Old Name")

    resp = client.patch(_detail(building.pk), {"name": "New Name"}, format="json")

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data["name"] == "New Name"
    building.refresh_from_db()
    assert building.name == "New Name"


def test_update_writes_audit(client: APIClient, landlord: User) -> None:
    building = BuildingFactory(owner=landlord, name="Before")

    client.patch(_detail(building.pk), {"name": "After"}, format="json")

    entry = AuditEntry.objects.get(action="building.update")
    assert entry.actor_id == landlord.pk
    assert entry.before == {"name": "Before"}
    assert entry.after == {"name": "After"}


def test_update_empty_body_rejected(client: APIClient, landlord: User) -> None:
    building = BuildingFactory(owner=landlord)

    resp = client.patch(_detail(building.pk), {}, format="json")

    assert resp.status_code == status.HTTP_400_BAD_REQUEST
    assert resp.data["error"]["code"] == "validation_error"


def test_update_other_users_building_404(client: APIClient) -> None:
    other_building = BuildingFactory(name="Theirs")

    resp = client.patch(_detail(other_building.pk), {"name": "Hijacked"}, format="json")

    assert resp.status_code == status.HTTP_404_NOT_FOUND
    other_building.refresh_from_db()
    assert other_building.name == "Theirs"  # untouched


# ── delete ───────────────────────────────────────────────────────────────────


def test_delete_building(client: APIClient, landlord: User) -> None:
    building = BuildingFactory(owner=landlord)

    resp = client.delete(_detail(building.pk))

    assert resp.status_code == status.HTTP_204_NO_CONTENT
    # Soft-deleted: gone from the default manager, present in all_objects.
    assert not Building.objects.filter(pk=building.pk).exists()
    refreshed = Building.all_objects.get(pk=building.pk)
    assert refreshed.deleted_at is not None


def test_delete_writes_audit(client: APIClient, landlord: User) -> None:
    building = BuildingFactory(owner=landlord, name="ToDelete")

    client.delete(_detail(building.pk))

    entry = AuditEntry.objects.get(action="building.delete")
    assert entry.actor_id == landlord.pk
    assert entry.target_id == str(building.pk)
    assert entry.before["name"] == "ToDelete"
    assert entry.after is None


def test_delete_other_users_building_404(client: APIClient) -> None:
    other_building = BuildingFactory()

    resp = client.delete(_detail(other_building.pk))

    assert resp.status_code == status.HTTP_404_NOT_FOUND
    assert Building.objects.filter(pk=other_building.pk).exists()  # untouched
