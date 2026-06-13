"""Verify the dashboard SystemConfig seeded by 0006_seed_dashboard_config."""

import pytest

from khatir.core.config import get_config
from khatir.core.models import SystemConfig

pytestmark = pytest.mark.django_db


def test_config_seeded() -> None:
    row = SystemConfig.objects.get(key="dashboard_months_default")
    assert row.type == "int"
    assert row.value == "6"
    assert row.description != ""


def test_config_typed_via_get_config() -> None:
    assert get_config("dashboard_months_default") == 6
