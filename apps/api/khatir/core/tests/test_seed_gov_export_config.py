"""Verify the gov-export SystemConfig seeded by core 0013 (EPIC-26.T-005)."""

import pytest

from khatir.core.config import get_config
from khatir.core.models import SystemConfig

pytestmark = pytest.mark.django_db

_KEY = "gov_export_format_version"
_VALUE = "2026.1"


def test_gov_export_config_seeded() -> None:
    row = SystemConfig.objects.get(key=_KEY)
    assert row.type == "text"
    assert row.value == _VALUE
    assert row.description != ""


def test_gov_export_config_typed_via_get_config() -> None:
    coerced = get_config(_KEY)
    assert isinstance(coerced, str)
    assert coerced == _VALUE


def test_gov_export_config_matches_builder_default() -> None:
    """Seeded version must match the builder's hard-coded fallback."""
    from khatir.govexport import builder

    assert get_config(_KEY) == builder.DEFAULT_FORMAT_VERSION
