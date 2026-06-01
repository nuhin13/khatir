"""Tests for the cached SystemConfig accessor."""

from decimal import Decimal

import pytest

from khatir.core.config import get_config, invalidate_config
from khatir.core.exceptions import NotFoundError
from khatir.core.models import SystemConfig

pytestmark = pytest.mark.django_db


def test_get_config_typed_int() -> None:
    SystemConfig.objects.create(key="free_tier_tenant_limit", value="2", type="int")
    val = get_config("free_tier_tenant_limit")
    assert val == 2
    assert isinstance(val, int)


def test_get_config_typed_money() -> None:
    SystemConfig.objects.create(key="late_fee", value="150.50", type="money")
    val = get_config("late_fee")
    assert val == Decimal("150.50")
    assert isinstance(val, Decimal)


def test_get_config_typed_bool() -> None:
    SystemConfig.objects.create(key="flag", value="true", type="bool")
    assert get_config("flag") is True


def test_get_config_typed_text() -> None:
    SystemConfig.objects.create(key="brand", value="Khatir", type="text")
    assert get_config("brand") == "Khatir"


def test_get_config_missing_raises() -> None:
    with pytest.raises(NotFoundError):
        get_config("nope")


def test_get_config_missing_with_default() -> None:
    assert get_config("nope", default=7) == 7


def test_get_config_caches_then_invalidates_on_write() -> None:
    cfg = SystemConfig.objects.create(key="k", value="10", type="int")
    assert get_config("k") == 10  # caches

    # Mutate via .update() so post_save does NOT fire — proves the value is cached.
    SystemConfig.objects.filter(pk=cfg.pk).update(value="99")
    assert get_config("k") == 10  # still cached

    # A normal save() fires post_save → cache invalidated.
    cfg.refresh_from_db()
    cfg.value = "42"
    cfg.save()
    assert get_config("k") == 42


def test_invalidate_config_forces_reload() -> None:
    cfg = SystemConfig.objects.create(key="k2", value="1", type="int")
    assert get_config("k2") == 1
    SystemConfig.objects.filter(pk=cfg.pk).update(value="5")
    invalidate_config("k2")
    assert get_config("k2") == 5


def test_delete_invalidates_cache() -> None:
    cfg = SystemConfig.objects.create(key="k3", value="1", type="int")
    assert get_config("k3") == 1
    cfg.delete()
    with pytest.raises(NotFoundError):
        get_config("k3")
