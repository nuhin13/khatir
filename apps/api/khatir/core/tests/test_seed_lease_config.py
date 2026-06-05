"""Verify the AI-lease SystemConfig seeded by 0013_seed_lease_config (T-005)."""

import pytest

from khatir.core.config import get_config
from khatir.core.models import SystemConfig

pytestmark = pytest.mark.django_db


def test_lease_config_seeded() -> None:
    version = SystemConfig.objects.get(key="lease_template_version")
    assert version.type == "text"
    assert version.value == "1.0"
    assert version.description != ""

    en = SystemConfig.objects.get(key="lease_disclaimer_text_en")
    assert en.type == "text"
    assert en.value == (
        "This is an AI-generated draft, not legal advice. Consult a lawyer."
    )
    assert en.description != ""

    bn = SystemConfig.objects.get(key="lease_disclaimer_text_bn")
    assert bn.type == "text"
    assert bn.value != ""
    assert bn.value != en.value
    assert bn.description != ""


def test_lease_config_typed_via_get_config() -> None:
    assert get_config("lease_template_version") == "1.0"
    assert get_config("lease_disclaimer_text_en") == (
        "This is an AI-generated draft, not legal advice. Consult a lawyer."
    )
    assert get_config("lease_disclaimer_text_bn") != ""


def test_disclaimer_states_not_legal_advice() -> None:
    """The mandatory disclaimer must declare the draft is not legal advice."""
    en = get_config("lease_disclaimer_text_en").lower()
    assert "not legal advice" in en
