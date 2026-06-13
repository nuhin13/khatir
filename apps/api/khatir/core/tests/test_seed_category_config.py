"""Verify the category SystemConfig keys seeded by 0006_seed_category_config."""

import json

import pytest
from rest_framework.test import APIClient

from khatir.core.config import get_config
from khatir.core.models import SystemConfig
from khatir.maintenance.enums import ExpenseCategory, MaintenanceCategory

pytestmark = pytest.mark.django_db


def test_categories_seeded() -> None:
    maintenance = SystemConfig.objects.get(key="maintenance_categories")
    expense = SystemConfig.objects.get(key="expense_categories")

    assert maintenance.type == "text"
    assert expense.type == "text"
    assert maintenance.description != ""
    assert expense.description != ""

    assert set(json.loads(maintenance.value)) == set(MaintenanceCategory.values)
    assert set(json.loads(expense.value)) == set(ExpenseCategory.values)


def test_categories_include_known_defaults() -> None:
    maintenance = json.loads(get_config("maintenance_categories"))
    expense = json.loads(get_config("expense_categories"))

    for expected in ("plumbing", "electrical", "paint", "other"):
        assert expected in maintenance
        assert expected in expense


def test_categories_surface_in_config_public() -> None:
    response = APIClient().get("/api/v1/config/public")
    assert response.status_code == 200

    config = response.json()["config"]
    assert config["maintenance_categories"] == json.loads(
        SystemConfig.objects.get(key="maintenance_categories").value
    )
    assert config["expense_categories"] == json.loads(
        SystemConfig.objects.get(key="expense_categories").value
    )
