"""Tests for ``MaintenanceRequest`` and ``Expense`` models (T-001 §12)."""

from __future__ import annotations

from decimal import Decimal

import pytest
from django.db import models

from khatir.maintenance.enums import (
    ExpenseCategory,
    ExpenseSource,
    MaintenanceCategory,
    MaintenanceStatus,
)
from khatir.maintenance.models import Expense, MaintenanceRequest

from .factories import ExpenseFactory, MaintenanceRequestFactory

pytestmark = pytest.mark.django_db


# --- MaintenanceRequest -----------------------------------------------------


def test_maintenance_request_create() -> None:
    req: MaintenanceRequest = MaintenanceRequestFactory(  # type: ignore[assignment]
        category=MaintenanceCategory.ELECTRICAL,
        description="Lights not working",
    )
    assert req.pk is not None
    assert req.unit_id is not None
    assert req.category == MaintenanceCategory.ELECTRICAL
    assert req.description == "Lights not working"
    assert req.status == MaintenanceStatus.OPEN
    assert req.lease_id is None
    assert req.photo_ref == ""
    assert req.resolved_at is None
    assert req.resolution_cost is None
    assert req.resolution_note == ""
    assert str(req) == f"MaintenanceRequest #{req.pk} — electrical (open)"


def test_maintenance_request_optional_fields_default() -> None:
    req: MaintenanceRequest = MaintenanceRequestFactory()  # type: ignore[assignment]
    req.refresh_from_db()
    assert req.lease_id is None
    assert req.photo_ref == ""
    assert req.resolved_at is None
    assert req.resolution_cost is None
    assert req.resolution_note == ""


def test_maintenance_request_resolution_cost_is_decimal() -> None:
    req: MaintenanceRequest = MaintenanceRequestFactory(  # type: ignore[assignment]
        resolution_cost=Decimal("3500.50"),
        status=MaintenanceStatus.RESOLVED,
    )
    req.refresh_from_db()
    assert isinstance(req.resolution_cost, Decimal)
    assert req.resolution_cost == Decimal("3500.50")


def test_maintenance_request_unit_fk_is_protect() -> None:
    field = MaintenanceRequest._meta.get_field("unit")
    assert isinstance(field, models.ForeignKey)
    assert field.remote_field.on_delete is models.PROTECT


def test_maintenance_request_lease_fk_is_set_null() -> None:
    field = MaintenanceRequest._meta.get_field("lease")
    assert isinstance(field, models.ForeignKey)
    assert field.null is True
    assert field.remote_field.on_delete is models.SET_NULL


def test_maintenance_request_soft_delete() -> None:
    req: MaintenanceRequest = MaintenanceRequestFactory()  # type: ignore[assignment]
    pk = req.pk
    req.delete()
    assert req.is_deleted is True
    assert MaintenanceRequest.objects.filter(pk=pk).count() == 0
    assert MaintenanceRequest.all_objects.filter(pk=pk).count() == 1


# --- Expense ----------------------------------------------------------------


def test_expense_create() -> None:
    expense: Expense = ExpenseFactory(  # type: ignore[assignment]
        category=ExpenseCategory.PAINT,
        amount=Decimal("12000.00"),
        source=ExpenseSource.MANUAL,
    )
    assert expense.pk is not None
    assert expense.unit_id is not None
    assert expense.category == ExpenseCategory.PAINT
    assert expense.amount == Decimal("12000.00")
    assert expense.source == ExpenseSource.MANUAL
    assert expense.receipt_ref == ""
    assert str(expense) == f"Expense #{expense.pk} — paint ৳12000.00"


def test_expense_amount_is_decimal() -> None:
    expense: Expense = ExpenseFactory(amount=Decimal("99999.99"))  # type: ignore[assignment]
    expense.refresh_from_db()
    assert isinstance(expense.amount, Decimal)
    assert expense.amount == Decimal("99999.99")


def test_expense_optional_fields_default() -> None:
    expense: Expense = ExpenseFactory()  # type: ignore[assignment]
    expense.refresh_from_db()
    assert expense.receipt_ref == ""
    assert expense.note != ""  # factory sets a sequence note


def test_expense_unit_fk_is_protect() -> None:
    field = Expense._meta.get_field("unit")
    assert isinstance(field, models.ForeignKey)
    assert field.remote_field.on_delete is models.PROTECT


def test_expense_source_request_allowed() -> None:
    expense: Expense = ExpenseFactory(source=ExpenseSource.REQUEST)  # type: ignore[assignment]
    assert expense.source == ExpenseSource.REQUEST


# --- Enums match enums.md ---------------------------------------------------


def test_maintenance_category_values_match_spec() -> None:
    assert set(MaintenanceCategory.values) == {
        "plumbing",
        "electrical",
        "paint",
        "structural",
        "appliance",
        "utility",
        "other",
    }


def test_maintenance_status_values_match_spec() -> None:
    assert set(MaintenanceStatus.values) == {"open", "resolved"}


def test_expense_category_values_match_spec() -> None:
    assert set(ExpenseCategory.values) == {
        "plumbing",
        "paint",
        "electrical",
        "structural",
        "appliance",
        "utility",
        "other",
    }


def test_expense_source_values_match_spec() -> None:
    assert set(ExpenseSource.values) == {"request", "manual"}


# --- Indexes ----------------------------------------------------------------


def test_expense_unit_date_index_present() -> None:
    index_fields = {tuple(idx.fields) for idx in Expense._meta.indexes}
    assert ("unit", "date") in index_fields


def test_maintenance_request_unit_status_index_present() -> None:
    index_fields = {tuple(idx.fields) for idx in MaintenanceRequest._meta.indexes}
    assert ("unit", "status") in index_fields
