"""Verify the ``area_options`` SystemConfig seeded by 0003_seed_area_options."""

import json

import pytest

from khatir.core.config import get_config
from khatir.core.enums import Area
from khatir.core.models import SystemConfig

pytestmark = pytest.mark.django_db


def test_area_options_seeded_from_enum() -> None:
    row = SystemConfig.objects.get(key="area_options")
    assert row.type == "text"
    assert row.description != ""
    assert json.loads(row.value) == [choice.value for choice in Area]


def test_area_options_includes_known_areas() -> None:
    areas = json.loads(get_config("area_options"))
    assert "uttara" in areas
    assert "other" in areas
    assert len(areas) == 10
