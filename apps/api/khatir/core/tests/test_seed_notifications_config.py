"""Verify the notifications cost SystemConfig seeded by 0011."""

from decimal import Decimal

import pytest

from khatir.core.config import get_config
from khatir.core.models import SystemConfig

pytestmark = pytest.mark.django_db

_EXPECTED = {
    "whatsapp_cost_per_message": "0.50",
    "sms_cost_per_message": "0.30",
    "email_cost_per_message": "0.00",
}


def test_notifications_cost_config_seeded() -> None:
    for key, value in _EXPECTED.items():
        row = SystemConfig.objects.get(key=key)
        assert row.type == "money"
        assert row.value == value
        assert row.description != ""


def test_notifications_cost_typed_via_get_config() -> None:
    for key, value in _EXPECTED.items():
        coerced = get_config(key)
        assert isinstance(coerced, Decimal)
        assert coerced == Decimal(value)
