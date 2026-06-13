"""Verify the admin-session SystemConfig seeded by 0009_seed_admin_config."""

import pytest

from khatir.core.config import get_config
from khatir.core.models import SystemConfig

pytestmark = pytest.mark.django_db


def test_admin_config_seeded() -> None:
    timeout = SystemConfig.objects.get(key="admin_session_timeout_minutes")
    assert timeout.type == "int"
    assert timeout.value == "60"
    assert timeout.description != ""

    mfa = SystemConfig.objects.get(key="admin_mfa_required")
    assert mfa.type == "bool"
    assert mfa.value == "true"
    assert mfa.description != ""


def test_admin_config_typed_via_get_config() -> None:
    assert get_config("admin_session_timeout_minutes") == 60
    assert get_config("admin_mfa_required") is True
