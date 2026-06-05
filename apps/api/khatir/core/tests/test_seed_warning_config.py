"""Verify the private-warning SystemConfig seeded by 0013 (EPIC-20.T-004)."""

import json

import pytest

from khatir.core.config import get_config
from khatir.core.models import SystemConfig

pytestmark = pytest.mark.django_db

_EXPECTED_TYPES = [
    "late_rent",
    "lease_violation",
    "noise",
    "property_damage",
    "other",
]


def test_warning_config_seeded() -> None:
    types_row = SystemConfig.objects.get(key="warning_types")
    assert types_row.type == "text"
    assert json.loads(types_row.value) == _EXPECTED_TYPES
    assert types_row.description != ""

    for key in ("warning_disclaimer_text_en", "warning_disclaimer_text_bn"):
        row = SystemConfig.objects.get(key=key)
        assert row.type == "text"
        assert row.value.strip() != ""
        assert row.description != ""


def test_warning_disclaimer_is_bilingual() -> None:
    en = get_config("warning_disclaimer_text_en")
    bn = get_config("warning_disclaimer_text_bn")
    # English disclaimer is ASCII; Bangla carries non-ASCII (Bengali) characters.
    assert en.isascii()
    assert not bn.isascii()
    assert en != bn


def test_warning_types_readable_via_get_config() -> None:
    raw = get_config("warning_types")
    assert json.loads(raw) == _EXPECTED_TYPES
