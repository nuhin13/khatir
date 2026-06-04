"""API tests for the maintenance CRUD + resolve endpoints (T-002 §12)."""

from __future__ import annotations

from decimal import Decimal

import pytest
from rest_framework import status
from rest_framework.test import APIClient

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.core.models import AuditEntry
from khatir.maintenance.enums import (
    ExpenseSource,
    MaintenanceCategory,
    MaintenanceStatus,
)
from khatir.maintenance.models import Expense, MaintenanceRequest
from khatir.properties.tests.factories import BuildingFactory, UnitFactory

from .factories import MaintenanceRequestFactory

pytestmark = pytest.mark.django_db

URL = "/api/v1/maintenance"


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
    return f"{URL}/{pk}"


def _resolve(pk: object) -> str:
    return f"{URL}/{pk}/resolve"


def test_create_open_request(client: APIClient, landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))
    resp = client.post(
        URL,
        {
            "unit_id": str(unit.pk),
            "description": "Tap is leaking",
            "category": MaintenanceCategory.PLUMBING.value,
        },
        format="json",
    )
    assert resp.status_code == status.HTTP_201_CREATED
    assert resp.data["status"] == MaintenanceStatus.OPEN.value
    assert resp.data["unit_id"] == str(unit.pk)
    req = MaintenanceRequest.objects.get(pk=resp.data["id"])
    assert req.unit_id == unit.pk
    assert req.description == "Tap is leaking"


def test_create_foreign_unit_404(client: APIClient) -> None:
    foreign_unit = UnitFactory()
    resp = client.post(
        URL, {"unit_id": str(foreign_unit.pk), "description": "x"}, format="json"
    )
    assert resp.status_code == status.HTTP_404_NOT_FOUND
    assert not MaintenanceRequest.objects.exists()


def test_create_writes_audit(client: APIClient, landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))
    resp = client.post(
        URL, {"unit_id": str(unit.pk), "description": "Tap"}, format="json"
    )
    entry = AuditEntry.objects.get(action="maintenance.create")
    assert entry.actor_id == landlord.pk
    assert entry.target_type == "maintenance.maintenancerequest"
    assert entry.target_id == str(resp.data["id"])


def test_create_requires_auth() -> None:
    resp = APIClient().post(URL, {}, format="json")
    assert resp.status_code == status.HTTP_401_UNAUTHORIZED


def test_tenant_role_forbidden() -> None:
    tenant_user: User = UserFactory(phone="+8801700000001", role=Role.TENANT)  # type: ignore[assignment]
    api = APIClient()
    api.force_authenticate(user=tenant_user)
    resp = api.get(URL)
    assert resp.status_code == status.HTTP_403_FORBIDDEN


def test_list_scoped_to_owner(client: APIClient, landlord: User) -> None:
    mine = MaintenanceRequestFactory(
        unit=UnitFactory(building=BuildingFactory(owner=landlord))
    )
    MaintenanceRequestFactory()
    resp = client.get(URL)
    assert resp.status_code == status.HTTP_200_OK
    ids = [row["id"] for row in resp.data["results"]]
    assert ids == [str(mine.pk)]
    assert resp.data["pagination"]["count"] == 1


def test_retrieve_other_users_request_404(client: APIClient) -> None:
    other = MaintenanceRequestFactory()
    resp = client.get(_detail(other.pk))
    assert resp.status_code == status.HTTP_404_NOT_FOUND
    assert resp.data["error"]["code"] == "not_found"


def test_update_open_request(client: APIClient, landlord: User) -> None:
    req = MaintenanceRequestFactory(
        unit=UnitFactory(building=BuildingFactory(owner=landlord))
    )
    resp = client.patch(_detail(req.pk), {"description": "Updated"}, format="json")
    assert resp.status_code == status.HTTP_200_OK
    req.refresh_from_db()
    assert req.description == "Updated"


def test_resolve_creates_one_expense(client: APIClient, landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))
    req = MaintenanceRequestFactory(unit=unit, category=MaintenanceCategory.PLUMBING)
    resp = client.post(
        _resolve(req.pk), {"cost": "3500.00", "note": "Replaced washer"}, format="json"
    )
    assert resp.status_code == status.HTTP_200_OK
    assert resp.data["status"] == MaintenanceStatus.RESOLVED.value
    assert resp.data["resolution_cost"] == "3500.00"
    req.refresh_from_db()
    assert req.resolved_at is not None
    expenses = Expense.objects.filter(request=req)
    assert expenses.count() == 1
    expense = expenses.get()
    assert expense.amount == Decimal("3500.00")
    assert expense.unit_id == unit.pk
    assert expense.source == ExpenseSource.REQUEST.value
    assert expense.category == MaintenanceCategory.PLUMBING.value


def test_resolve_writes_audit(client: APIClient, landlord: User) -> None:
    req = MaintenanceRequestFactory(
        unit=UnitFactory(building=BuildingFactory(owner=landlord))
    )
    client.post(_resolve(req.pk), {"cost": "100.00"}, format="json")
    entry = AuditEntry.objects.get(action="maintenance.resolve")
    assert entry.actor_id == landlord.pk
    assert entry.before == {"status": MaintenanceStatus.OPEN.value}
    assert entry.after["status"] == MaintenanceStatus.RESOLVED.value
    assert entry.after["resolution_cost"] == "100.00"


def test_double_resolve_does_not_create_second_expense(
    client: APIClient, landlord: User
) -> None:
    req = MaintenanceRequestFactory(
        unit=UnitFactory(building=BuildingFactory(owner=landlord))
    )
    first = client.post(_resolve(req.pk), {"cost": "500.00"}, format="json")
    assert first.status_code == status.HTTP_200_OK
    second = client.post(_resolve(req.pk), {"cost": "999.00"}, format="json")
    assert second.status_code == status.HTTP_400_BAD_REQUEST
    assert Expense.objects.filter(request=req).count() == 1
    assert Expense.objects.get(request=req).amount == Decimal("500.00")


def test_resolve_foreign_request_404(client: APIClient) -> None:
    other = MaintenanceRequestFactory()
    resp = client.post(_resolve(other.pk), {"cost": "100.00"}, format="json")
    assert resp.status_code == status.HTTP_404_NOT_FOUND
    assert not Expense.objects.exists()
