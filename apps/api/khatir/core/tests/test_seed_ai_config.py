"""Verify the AI-gateway SystemConfig seeded by 0010_seed_ai_config."""

import pytest

from khatir.core.config import get_config
from khatir.core.models import SystemConfig

pytestmark = pytest.mark.django_db


def test_ai_config_seeded() -> None:
    url = SystemConfig.objects.get(key="ai_gateway_url")
    assert url.type == "text"
    assert url.description != ""

    secret = SystemConfig.objects.get(key="ai_gateway_secret")
    assert secret.type == "text"
    # Seeded empty: the real secret is supplied out-of-band, never embedded.
    assert secret.value == ""
    assert secret.description != ""

    ttl = SystemConfig.objects.get(key="ai_provider_cache_ttl_seconds")
    assert ttl.type == "int"
    assert ttl.value == "300"
    assert ttl.description != ""


def test_ai_config_typed_via_get_config() -> None:
    assert get_config("ai_gateway_url") == ""
    assert get_config("ai_gateway_secret") == ""
    assert get_config("ai_provider_cache_ttl_seconds") == 300
