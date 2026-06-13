"""API tests for the expense CRUD + filtered list + CSV export endpoints (T-003 §12).

Exercises ``/api/v1/expenses`` through DRF's ``APIClient`` with real authenticated
landlords. Covers manual create (source forced to ``manual``), update/delete
restricted to manual expenses, the building/unit/date filters, the CSV export
(scoped + filtered), audit writes, role gating, and the cross-user **404**
(foreign expenses are invisible, never 403, T-003 §15).
"""

from __future__ import annotations

import datetime
from decimal import Decimal

import pytest
from rest_framework import status
from rest_framework.test import APIClient

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.core.models import AuditEntry
from khatir.maintenance.enums import ExpenseCategory, ExpenseSource
from khatir.maintenance.models import Expense
from khatir.maintenance.tests.factories import ExpenseFactory
from khatir.properties.tests.factories import BuildingFactory, UnitFactory

pytestmark = pytest.mark.django_db

EXPENSES_URL = "/api/v1/expenses"
EXPORT_URL = f"{EXPENSES_URL}/export"


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
    return f"{EXPENSES_URL}/{pk}"


def _create_body(unit_id: object) -> dict[str, object]:
    return {
        "unit_id": str(unit_id),
        "amount": "5000.00",
        "date": "2026-03-15",
        "category": ExpenseCategory.PLUMBING.value,
        "note": "Fixed a leak",
    }


# ── create ──────────────────────────────────────────────────────────────────


def test_create_manual_expense(client: APIClient, landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))

    resp = client.post(EXPENSES_URL, _create_body(unit.pk), format="json")

    assert resp.status_code == status.HTTP_201_CREATED
    assert resp.data["source"] == ExpenseSource.MANUAL.value
    assert resp.data["unit_id"] == str(unit.pk)
    expense = Expense.objects.get(pk=resp.data["id"])
    assert expense.amount == Decimal("5000.00")
    assert expense.source == ExpenseSource.MANUAL.value


def test_create_forces_manual_source(client: APIClient, landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))
    body = _create_body(unit.pk)
    body["source"] = ExpenseSource.REQUEST.value  # should be ignored

    resp = client.post(EXPENSES_URL, body, format="json")

    assert resp.status_code == status.HTTP_201_CREATED
    expense = Expense.objects.get(pk=resp.data["id"])
    assert expense.source == ExpenseSource.MANUAL.value


def test_create_writes_audit(client: APIClient, landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))

    resp = client.post(EXPENSES_URL, _create_body(unit.pk), format="json")

    entry = AuditEntry.objects.get(action="expense.create")
    assert entry.actor_id == landlord.pk
    assert entry.target_type == "maintenance.expense"
    assert entry.target_id == str(resp.data["id"])
    assert entry.before is None
    assert entry.after["source"] == ExpenseSource.MANUAL.value


def test_create_foreign_unit_404(client: APIClient) -> None:
    foreign_unit = UnitFactory()  # belongs to a different landlord

    resp = client.post(EXPENSES_URL, _create_body(foreign_unit.pk), format="json")

    # 404, never 403 — we do not reveal the unit exists (T-003 §15).
    assert resp.status_code == status.HTTP_404_NOT_FOUND
    assert not Expense.objects.exists()


def test_create_negative_amount_rejected(client: APIClient, landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))
    body = _create_body(unit.pk)
    body["amount"] = "-1.00"

    resp = client.post(EXPENSES_URL, body, format="json")

    assert resp.status_code == status.HTTP_400_BAD_REQUEST
    assert resp.data["error"]["code"] == "validation_error"


# ── auth / role ──────────────────────────────────────────────────────────────


def test_list_requires_auth() -> None:
    resp = APIClient().get(EXPENSES_URL)
    assert resp.status_code == status.HTTP_401_UNAUTHORIZED


def test_tenant_role_forbidden() -> None:
    tenant_user: User = UserFactory(phone="+8801700000001", role=Role.TENANT)  # type: ignore[assignment]
    api = APIClient()
    api.force_authenticate(user=tenant_user)

    resp = api.get(EXPENSES_URL)

    assert resp.status_code == status.HTTP_403_FORBIDDEN


# ── list / retrieve (scoped + filtered) ───────────────────────────────────────


def test_list_scoped_to_landlord(client: APIClient, landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))
    mine = ExpenseFactory(unit=unit)
    ExpenseFactory()  # someone else's

    resp = client.get(EXPENSES_URL)

    assert resp.status_code == status.HTTP_200_OK
    ids = [row["id"] for row in resp.data["results"]]
    assert ids == [str(mine.pk)]
    assert resp.data["pagination"]["count"] == 1


def test_list_includes_auto_expense(client: APIClient, landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))
    ExpenseFactory(unit=unit, source=ExpenseSource.MANUAL)
    ExpenseFactory(unit=unit, source=ExpenseSource.REQUEST)

    resp = client.get(EXPENSES_URL)

    assert resp.data["pagination"]["count"] == 2


def test_retrieve_other_users_expense_404(client: APIClient) -> None:
    other = ExpenseFactory()  # belongs to a different landlord

    resp = client.get(_detail(other.pk))

    assert resp.status_code == status.HTTP_404_NOT_FOUND
    assert resp.data["error"]["code"] == "not_found"


def test_filter_by_unit(client: APIClient, landlord: User) -> None:
    building = BuildingFactory(owner=landlord)
    unit_a = UnitFactory(building=building)
    unit_b = UnitFactory(building=building)
    wanted = ExpenseFactory(unit=unit_a)
    ExpenseFactory(unit=unit_b)

    resp = client.get(EXPENSES_URL, {"unit": str(unit_a.pk)})

    ids = [row["id"] for row in resp.data["results"]]
    assert ids == [str(wanted.pk)]


def test_filter_by_building(client: APIClient, landlord: User) -> None:
    building_a = BuildingFactory(owner=landlord)
    building_b = BuildingFactory(owner=landlord)
    wanted = ExpenseFactory(unit=UnitFactory(building=building_a))
    ExpenseFactory(unit=UnitFactory(building=building_b))

    resp = client.get(EXPENSES_URL, {"building": str(building_a.pk)})

    ids = [row["id"] for row in resp.data["results"]]
    assert ids == [str(wanted.pk)]


def test_filter_by_date_range(client: APIClient, landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))
    inside = ExpenseFactory(unit=unit, date=datetime.date(2026, 6, 15))
    ExpenseFactory(unit=unit, date=datetime.date(2026, 1, 1))
    ExpenseFactory(unit=unit, date=datetime.date(2026, 12, 31))

    resp = client.get(
        EXPENSES_URL, {"date_from": "2026-06-01", "date_to": "2026-06-30"}
    )

    ids = [row["id"] for row in resp.data["results"]]
    assert ids == [str(inside.pk)]


# ── update / delete (manual only) ──────────────────────────────────────────────


def test_update_manual_expense(client: APIClient, landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))
    expense = ExpenseFactory(unit=unit, amount=Decimal("100.00"))

    resp = client.patch(_detail(expense.pk), {"amount": "250.00"}, format="json")

    assert resp.status_code == status.HTTP_200_OK
    expense.refresh_from_db()
    assert expense.amount == Decimal("250.00")
    assert AuditEntry.objects.filter(action="expense.update").exists()


def test_update_auto_expense_rejected(client: APIClient, landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))
    expense = ExpenseFactory(unit=unit, source=ExpenseSource.REQUEST)

    resp = client.patch(_detail(expense.pk), {"amount": "250.00"}, format="json")

    assert resp.status_code == status.HTTP_400_BAD_REQUEST


def test_delete_manual_expense(client: APIClient, landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))
    expense = ExpenseFactory(unit=unit)

    resp = client.delete(_detail(expense.pk))

    assert resp.status_code == status.HTTP_204_NO_CONTENT
    assert not Expense.objects.filter(pk=expense.pk).exists()  # soft-deleted (hidden)
    assert AuditEntry.objects.filter(action="expense.delete").exists()


def test_delete_auto_expense_rejected(client: APIClient, landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))
    expense = ExpenseFactory(unit=unit, source=ExpenseSource.REQUEST)

    resp = client.delete(_detail(expense.pk))

    assert resp.status_code == status.HTTP_400_BAD_REQUEST
    assert Expense.objects.filter(pk=expense.pk).exists()


def test_delete_foreign_expense_404(client: APIClient) -> None:
    other = ExpenseFactory()

    resp = client.delete(_detail(other.pk))

    assert resp.status_code == status.HTTP_404_NOT_FOUND


# ── CSV export (scoped + filtered) ─────────────────────────────────────────────


def _csv_text(resp: object) -> str:
    return b"".join(resp.streaming_content).decode("utf-8")  # type: ignore[attr-defined]


def _csv_ids(resp: object) -> set[str]:
    """The set of expense ids (first column) from a CSV export, header excluded."""
    lines = _csv_text(resp).splitlines()
    return {line.split(",", 1)[0] for line in lines[1:] if line}


def test_export_csv(client: APIClient, landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))
    expense = ExpenseFactory(unit=unit, amount=Decimal("5000.00"))

    resp = client.get(EXPORT_URL)

    assert resp.status_code == status.HTTP_200_OK
    assert resp["Content-Type"] == "text/csv"
    assert "attachment" in resp["Content-Disposition"]
    text = _csv_text(resp)
    assert text.splitlines()[0].startswith("id,unit_id,category,amount,date,source")
    assert str(expense.pk) in text
    assert "5000.00" in text


def test_export_csv_scoped(client: APIClient, landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))
    mine = ExpenseFactory(unit=unit)
    foreign = ExpenseFactory()  # different landlord

    resp = client.get(EXPORT_URL)

    ids = _csv_ids(resp)
    assert str(mine.pk) in ids
    assert str(foreign.pk) not in ids


def test_export_csv_respects_filters(client: APIClient, landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))
    inside = ExpenseFactory(unit=unit, date=datetime.date(2026, 6, 15))
    outside = ExpenseFactory(unit=unit, date=datetime.date(2026, 1, 1))

    resp = client.get(EXPORT_URL, {"date_from": "2026-06-01", "date_to": "2026-06-30"})

    ids = _csv_ids(resp)
    assert str(inside.pk) in ids
    assert str(outside.pk) not in ids


def test_export_requires_auth() -> None:
    resp = APIClient().get(EXPORT_URL)
    assert resp.status_code == status.HTTP_401_UNAUTHORIZED
