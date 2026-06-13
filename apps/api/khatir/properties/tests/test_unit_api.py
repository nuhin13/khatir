"""API tests for the unit CRUD + bulk-generate endpoints (T-004 §12).

Exercises ``/api/v1/buildings/{id}/units``, ``…/units/generate`` and
``/api/v1/units/{id}`` through DRF's ``APIClient`` with a real authenticated
landlord. Covers generation vectors end-to-end, single create, CRUD, audit
writes, and — critically — the cross-user **404** (other users' units/buildings
are invisible, never 403, T-004 §2 mirrors T-003 §15).
"""

from __future__ import annotations

from decimal import Decimal

import pytest
from rest_framework import status
from rest_framework.test import APIClient

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.core.models import AuditEntry
from khatir.properties.enums import UnitScheme, UnitStatus, UnitType
from khatir.properties.models import Building, Unit

from .factories import BuildingFactory, UnitFactory

pytestmark = pytest.mark.django_db


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


@pytest.fixture
def building(landlord: User) -> Building:
    return BuildingFactory(owner=landlord)


def _units_url(building_pk: object) -> str:
    return f"/api/v1/buildings/{building_pk}/units"


def _generate_url(building_pk: object) -> str:
    return f"/api/v1/buildings/{building_pk}/units/generate"


def _unit_detail(pk: object) -> str:
    return f"/api/v1/units/{pk}"


# ── generate ──────────────────────────────────────────────────────────────────


def test_generate_letter(client: APIClient, building: Building) -> None:
    resp = client.post(
        _generate_url(building.pk),
        {"floors": 3, "per_floor": 2, "scheme": UnitScheme.LETTER.value},
        format="json",
    )

    assert resp.status_code == status.HTTP_201_CREATED
    labels = [u["label"] for u in resp.data]
    assert labels == ["1A", "1B", "2A", "2B", "3A", "3B"]
    assert Unit.objects.filter(building=building).count() == 6


def test_generate_number(client: APIClient, building: Building) -> None:
    resp = client.post(
        _generate_url(building.pk),
        {"floors": 3, "per_floor": 2, "scheme": UnitScheme.NUMBER.value},
        format="json",
    )

    assert resp.status_code == status.HTTP_201_CREATED
    labels = [u["label"] for u in resp.data]
    assert labels == ["101", "102", "201", "202", "301", "302"]


def test_generate_with_custom(client: APIClient, building: Building) -> None:
    resp = client.post(
        _generate_url(building.pk),
        {
            "floors": 1,
            "per_floor": 2,
            "scheme": UnitScheme.NUMBER.value,
            "custom": ["2001", "GA"],
        },
        format="json",
    )

    assert resp.status_code == status.HTTP_201_CREATED
    labels = [u["label"] for u in resp.data]
    assert labels == ["101", "102", "2001", "GA"]


def test_generate_with_removed(client: APIClient, building: Building) -> None:
    resp = client.post(
        _generate_url(building.pk),
        {
            "floors": 2,
            "per_floor": 2,
            "scheme": UnitScheme.LETTER.value,
            "removed": ["1B", "2A"],
        },
        format="json",
    )

    assert resp.status_code == status.HTTP_201_CREATED
    labels = [u["label"] for u in resp.data]
    assert labels == ["1A", "2B"]


def test_generate_skips_existing_labels(client: APIClient, building: Building) -> None:
    UnitFactory(building=building, label="1A")

    resp = client.post(
        _generate_url(building.pk),
        {"floors": 1, "per_floor": 2, "scheme": UnitScheme.LETTER.value},
        format="json",
    )

    assert resp.status_code == status.HTTP_201_CREATED
    # Only the missing label is created; existing "1A" is not duplicated.
    assert [u["label"] for u in resp.data] == ["1B"]
    assert Unit.objects.filter(building=building).count() == 2


def test_generate_writes_audit(
    client: APIClient, building: Building, landlord: User
) -> None:
    client.post(
        _generate_url(building.pk),
        {"floors": 2, "per_floor": 1, "scheme": UnitScheme.NUMBER.value},
        format="json",
    )

    entry = AuditEntry.objects.get(action="unit.generate")
    assert entry.actor_id == landlord.pk
    assert entry.target_type == "properties.building"
    assert entry.target_id == str(building.pk)
    assert entry.after["created_labels"] == ["101", "201"]


def test_generate_rejects_invalid_scheme(
    client: APIClient, building: Building
) -> None:
    resp = client.post(
        _generate_url(building.pk),
        {"floors": 2, "per_floor": 2, "scheme": "roman"},
        format="json",
    )

    assert resp.status_code == status.HTTP_400_BAD_REQUEST
    assert resp.data["error"]["code"] == "validation_error"
    assert "scheme" in resp.data["error"]["details"]


def test_generate_rejects_zero_floors(client: APIClient, building: Building) -> None:
    resp = client.post(
        _generate_url(building.pk),
        {"floors": 0, "per_floor": 2, "scheme": UnitScheme.LETTER.value},
        format="json",
    )

    assert resp.status_code == status.HTTP_400_BAD_REQUEST
    assert "floors" in resp.data["error"]["details"]


def test_generate_other_users_building_404(client: APIClient) -> None:
    other = BuildingFactory()

    resp = client.post(
        _generate_url(other.pk),
        {"floors": 2, "per_floor": 2, "scheme": UnitScheme.LETTER.value},
        format="json",
    )

    assert resp.status_code == status.HTTP_404_NOT_FOUND
    assert Unit.objects.filter(building=other).count() == 0


# ── single create ──────────────────────────────────────────────────────────────


def test_create_unit(client: APIClient, building: Building) -> None:
    resp = client.post(
        _units_url(building.pk),
        {
            "label": "4B",
            "type": UnitType.APARTMENT.value,
            "rent": "15000.00",
            "status": UnitStatus.VACANT.value,
            "amenities": ["lift", "parking"],
        },
        format="json",
    )

    assert resp.status_code == status.HTTP_201_CREATED
    assert resp.data["label"] == "4B"
    assert resp.data["building_id"] == str(building.pk)
    assert resp.data["amenities"] == ["lift", "parking"]
    unit = Unit.objects.get(pk=resp.data["id"])
    assert unit.building_id == building.pk
    assert unit.rent == Decimal("15000.00")


def test_create_unit_defaults(client: APIClient, building: Building) -> None:
    resp = client.post(_units_url(building.pk), {"label": "1A"}, format="json")

    assert resp.status_code == status.HTTP_201_CREATED
    assert resp.data["type"] == UnitType.APARTMENT.value
    assert resp.data["status"] == UnitStatus.VACANT.value
    assert resp.data["rent"] == "0.00"


def test_create_unit_writes_audit(
    client: APIClient, building: Building, landlord: User
) -> None:
    resp = client.post(_units_url(building.pk), {"label": "2C"}, format="json")

    entry = AuditEntry.objects.get(action="unit.create")
    assert entry.actor_id == landlord.pk
    assert entry.target_type == "properties.unit"
    assert entry.target_id == str(resp.data["id"])
    assert entry.before is None
    assert entry.after["label"] == "2C"


def test_create_unit_requires_label(client: APIClient, building: Building) -> None:
    resp = client.post(_units_url(building.pk), {}, format="json")

    assert resp.status_code == status.HTTP_400_BAD_REQUEST
    assert "label" in resp.data["error"]["details"]


def test_create_unit_other_users_building_404(client: APIClient) -> None:
    other = BuildingFactory()

    resp = client.post(_units_url(other.pk), {"label": "X"}, format="json")

    assert resp.status_code == status.HTTP_404_NOT_FOUND
    assert Unit.objects.filter(building=other).count() == 0


# ── list (scoped) ───────────────────────────────────────────────────────────────


def test_list_units_scoped_to_building(
    client: APIClient, building: Building
) -> None:
    UnitFactory(building=building, label="1A")
    UnitFactory(building=building, label="1B")
    UnitFactory()  # someone else's building/unit

    resp = client.get(_units_url(building.pk))

    assert resp.status_code == status.HTTP_200_OK
    labels = sorted(row["label"] for row in resp.data["results"])
    assert labels == ["1A", "1B"]
    assert resp.data["pagination"]["count"] == 2


def test_list_units_other_users_building_404(client: APIClient) -> None:
    other = BuildingFactory()
    UnitFactory(building=other)

    resp = client.get(_units_url(other.pk))

    assert resp.status_code == status.HTTP_404_NOT_FOUND


def test_list_units_requires_auth(building: Building) -> None:
    resp = APIClient().get(_units_url(building.pk))
    assert resp.status_code == status.HTTP_401_UNAUTHORIZED


# ── retrieve / update / delete (top-level /units/{id}) ──────────────────────────


def test_retrieve_unit(client: APIClient, building: Building) -> None:
    unit = UnitFactory(building=building, label="3A")

    resp = client.get(_unit_detail(unit.pk))

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data["id"] == str(unit.pk)
    assert resp.data["label"] == "3A"


def test_update_unit(client: APIClient, building: Building) -> None:
    unit = UnitFactory(building=building, status=UnitStatus.VACANT)

    resp = client.patch(
        _unit_detail(unit.pk),
        {"status": UnitStatus.OCCUPIED.value, "rent": "20000.00"},
        format="json",
    )

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data["status"] == UnitStatus.OCCUPIED.value
    unit.refresh_from_db()
    assert unit.status == UnitStatus.OCCUPIED
    assert unit.rent == Decimal("20000.00")


def test_update_unit_writes_audit(
    client: APIClient, building: Building, landlord: User
) -> None:
    unit = UnitFactory(building=building, label="Before")

    client.patch(_unit_detail(unit.pk), {"label": "After"}, format="json")

    entry = AuditEntry.objects.get(action="unit.update")
    assert entry.actor_id == landlord.pk
    assert entry.before == {"label": "Before"}
    assert entry.after == {"label": "After"}


def test_update_unit_empty_body_rejected(
    client: APIClient, building: Building
) -> None:
    unit = UnitFactory(building=building)

    resp = client.patch(_unit_detail(unit.pk), {}, format="json")

    assert resp.status_code == status.HTTP_400_BAD_REQUEST
    assert resp.data["error"]["code"] == "validation_error"


def test_delete_unit(client: APIClient, building: Building) -> None:
    unit = UnitFactory(building=building)

    resp = client.delete(_unit_detail(unit.pk))

    assert resp.status_code == status.HTTP_204_NO_CONTENT
    assert not Unit.objects.filter(pk=unit.pk).exists()
    refreshed = Unit.all_objects.get(pk=unit.pk)
    assert refreshed.deleted_at is not None


def test_delete_unit_writes_audit(
    client: APIClient, building: Building, landlord: User
) -> None:
    unit = UnitFactory(building=building, label="ToDelete")

    client.delete(_unit_detail(unit.pk))

    entry = AuditEntry.objects.get(action="unit.delete")
    assert entry.actor_id == landlord.pk
    assert entry.target_id == str(unit.pk)
    assert entry.before["label"] == "ToDelete"
    assert entry.after is None


# ── cross-user isolation on the detail endpoint ────────────────────────────────


def test_retrieve_other_users_unit_404(client: APIClient) -> None:
    other_unit = UnitFactory()  # belongs to a different landlord's building

    resp = client.get(_unit_detail(other_unit.pk))

    # 404, never 403 — we do not reveal that the unit exists.
    assert resp.status_code == status.HTTP_404_NOT_FOUND
    assert resp.data["error"]["code"] == "not_found"


def test_update_other_users_unit_404(client: APIClient) -> None:
    other_unit = UnitFactory(label="Theirs")

    resp = client.patch(
        _unit_detail(other_unit.pk), {"label": "Hijacked"}, format="json"
    )

    assert resp.status_code == status.HTTP_404_NOT_FOUND
    other_unit.refresh_from_db()
    assert other_unit.label == "Theirs"  # untouched


def test_delete_other_users_unit_404(client: APIClient) -> None:
    other_unit = UnitFactory()

    resp = client.delete(_unit_detail(other_unit.pk))

    assert resp.status_code == status.HTTP_404_NOT_FOUND
    assert Unit.objects.filter(pk=other_unit.pk).exists()  # untouched


def test_unit_tenant_forbidden(building: Building) -> None:
    unit = UnitFactory(building=building)
    tenant: User = UserFactory(phone="+8801700000001", role=Role.TENANT)  # type: ignore[assignment]
    api = APIClient()
    api.force_authenticate(user=tenant)

    resp = api.get(_unit_detail(unit.pk))

    # Tenant fails the role gate before object scoping is even consulted.
    assert resp.status_code == status.HTTP_403_FORBIDDEN
