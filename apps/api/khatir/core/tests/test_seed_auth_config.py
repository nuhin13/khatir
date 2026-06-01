"""Verify the auth SystemConfig keys seeded by 0002_seed_auth_config."""

import pytest

from khatir.core.config import get_config
from khatir.core.models import SystemConfig

pytestmark = pytest.mark.django_db


def test_all_auth_keys_seeded() -> None:
    expected = {
        "otp_length": "int",
        "otp_ttl_seconds": "int",
        "otp_max_attempts": "int",
        "otp_resend_cooldown_seconds": "int",
        "auth_primary_channel": "text",
        "intro_slide_skip_allowed": "bool",
    }
    rows = {row.key: row for row in SystemConfig.objects.filter(key__in=expected)}
    assert set(rows) == set(expected)
    for key, type_ in expected.items():
        assert rows[key].type == type_
        assert rows[key].description != ""


def test_get_config_returns_typed_values() -> None:
    assert get_config("otp_length") == 6
    assert isinstance(get_config("otp_length"), int)
    assert get_config("otp_ttl_seconds") == 300
    assert get_config("otp_max_attempts") == 5
    assert get_config("otp_resend_cooldown_seconds") == 60
    assert get_config("auth_primary_channel") == "whatsapp"
    assert get_config("intro_slide_skip_allowed") is True
