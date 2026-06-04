"""Verify the lease SystemConfig keys seeded by 0002_seed_lease_config."""

import pytest

from khatir.core.config import get_config
from khatir.core.models import SystemConfig

pytestmark = pytest.mark.django_db


def test_lease_config_seeded() -> None:
    expected = {
        "default_due_day": "int",
        "rent_overdue_grace_days": "int",
    }
    rows = {row.key: row for row in SystemConfig.objects.filter(key__in=expected)}
    assert set(rows) == set(expected)
    for key, type_ in expected.items():
        assert rows[key].type == type_
        assert rows[key].description != ""


def test_get_config_returns_lease_defaults() -> None:
    assert get_config("default_due_day") == 5
    assert isinstance(get_config("default_due_day"), int)
    assert get_config("rent_overdue_grace_days") == 3
    assert isinstance(get_config("rent_overdue_grace_days"), int)
