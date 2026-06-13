"""Verify the ``dmp_template_version`` SystemConfig seeded by
0002_seed_template_version (EPIC-05.T-006)."""

import pytest

from khatir.core.config import get_config
from khatir.core.enums import SystemConfigType
from khatir.core.models import SystemConfig

pytestmark = pytest.mark.django_db


def test_template_version_seeded() -> None:
    row = SystemConfig.objects.get(key="dmp_template_version")
    assert row.type == SystemConfigType.TEXT
    assert row.value == "2026.1"
    assert row.description != ""


def test_template_version_config_accessor() -> None:
    assert get_config("dmp_template_version") == "2026.1"
