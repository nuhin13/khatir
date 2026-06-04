"""Verify the rent-collection SystemConfig seeded by 0004_seed_rent_config."""

import json

import pytest

from khatir.core.config import get_config
from khatir.core.models import SystemConfig

pytestmark = pytest.mark.django_db


def test_rent_config_seeded() -> None:
    cadence = SystemConfig.objects.get(key="rent_reminder_cadence_hours")
    assert cadence.type == "text"
    assert cadence.description != ""
    assert json.loads(cadence.value) == [24, 48]

    ttl = SystemConfig.objects.get(key="rent_link_token_ttl_hours")
    assert ttl.type == "int"
    assert ttl.description != ""

    proof = SystemConfig.objects.get(key="payment_proof_types")
    assert proof.type == "text"
    assert proof.description != ""
    assert json.loads(proof.value) == ["bkash_txn", "nagad_txn", "screenshot", "note"]


def test_rent_config_typed_via_get_config() -> None:
    assert get_config("rent_link_token_ttl_hours") == 168
    assert json.loads(get_config("rent_reminder_cadence_hours")) == [24, 48]
    assert "bkash_txn" in json.loads(get_config("payment_proof_types"))
