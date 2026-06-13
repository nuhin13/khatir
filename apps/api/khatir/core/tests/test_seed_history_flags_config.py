"""Verify the history-flags SystemConfig seeded by 0013 (EPIC-24.T-005)."""

import pytest

from khatir.core.config import get_config
from khatir.core.models import SystemConfig

pytestmark = pytest.mark.django_db

_EXPECTED_INT = {
    "history_share_default_expiry_days": 30,
}
_TEXT_KEY = "history_share_disclaimer_text"


def test_history_flags_int_config_seeded() -> None:
    for key, value in _EXPECTED_INT.items():
        row = SystemConfig.objects.get(key=key)
        assert row.type == "int"
        assert row.value == str(value)
        assert row.description != ""


def test_history_flags_int_typed_via_get_config() -> None:
    for key, value in _EXPECTED_INT.items():
        coerced = get_config(key)
        assert isinstance(coerced, int)
        assert coerced == value


def test_history_flags_disclaimer_seeded() -> None:
    row = SystemConfig.objects.get(key=_TEXT_KEY)
    assert row.type == "text"
    assert row.value.strip() != ""
    assert row.description != ""


def test_history_flags_disclaimer_via_get_config() -> None:
    coerced = get_config(_TEXT_KEY)
    assert isinstance(coerced, str)
    assert coerced.strip() != ""
