"""Verify the compliance SLA SystemConfig seeded by 0012."""

import pytest

from khatir.core.config import get_config
from khatir.core.models import SystemConfig

pytestmark = pytest.mark.django_db

_EXPECTED = {
    "data_request_sla_days": 30,
    "data_delete_grace_days": 7,
}


def test_compliance_config_seeded() -> None:
    for key, value in _EXPECTED.items():
        row = SystemConfig.objects.get(key=key)
        assert row.type == "int"
        assert row.value == str(value)
        assert row.description != ""


def test_compliance_config_typed_via_get_config() -> None:
    for key, value in _EXPECTED.items():
        coerced = get_config(key)
        assert isinstance(coerced, int)
        assert coerced == value
