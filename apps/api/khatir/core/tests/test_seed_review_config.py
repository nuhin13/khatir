"""Verify the mutual-review SystemConfig seeded by 0013 (EPIC-21.T-004)."""

import json

import pytest

from khatir.core.config import get_config
from khatir.core.models import SystemConfig

pytestmark = pytest.mark.django_db


def test_review_config_seeded() -> None:
    rating = SystemConfig.objects.get(key="review_rating_scale")
    assert rating.type == "int"
    assert rating.value == "5"
    assert rating.description != ""

    disclaimer = SystemConfig.objects.get(key="review_disclaimer_text")
    assert disclaimer.type == "text"
    assert disclaimer.description != ""


def test_review_rating_scale_typed_via_get_config() -> None:
    value = get_config("review_rating_scale")
    assert isinstance(value, int)
    assert value == 5


def test_review_disclaimer_is_bilingual_and_private() -> None:
    raw = get_config("review_disclaimer_text")
    payload = json.loads(raw)

    assert set(payload) == {"bn", "en"}
    for lang in ("bn", "en"):
        assert payload[lang].strip()

    # The disclaimer must make clear reviews are private and never published.
    en = payload["en"].lower()
    assert "private" in en
    assert "never publishes" in en or "never published" in en
    assert "no public" in en
