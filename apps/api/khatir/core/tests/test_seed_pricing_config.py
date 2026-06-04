"""Verify the pricing SystemConfig seeded by 0008_seed_pricing_config (EPIC-10.T-006)."""

import json

import pytest

from khatir.core.config import get_config
from khatir.core.models import SystemConfig

pytestmark = pytest.mark.django_db


def test_pricing_config_seeded() -> None:
    free_tier = SystemConfig.objects.get(key="free_tier_tenant_limit")
    assert free_tier.type == "int"
    assert get_config("free_tier_tenant_limit") == 2

    tiers_row = SystemConfig.objects.get(key="nid_verification_tiers")
    assert tiers_row.type == "text"
    assert tiers_row.description != ""
    assert json.loads(tiers_row.value) == [
        "bundle_10",
        "bundle_20",
        "bundle_50",
        "unlimited",
    ]
