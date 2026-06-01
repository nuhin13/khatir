"""Cached ``SystemConfig`` accessor (Layer-3 config).

``get_config(key)`` returns the value coerced to the Python type indicated by
``SystemConfig.type`` (int/money/text/bool), cached for 60s and invalidated on
write (``03_env_and_config.md`` §4).
"""

from __future__ import annotations

from decimal import Decimal
from typing import Any

from django.core.cache import cache
from django.db.models.signals import post_delete, post_save
from django.dispatch import receiver

from .enums import SystemConfigType
from .exceptions import NotFoundError
from .models import SystemConfig

_CACHE_TTL = 60  # seconds
_CACHE_PREFIX = "systemconfig:"
_MISSING = object()


def _cache_key(key: str) -> str:
    return f"{_CACHE_PREFIX}{key}"


def _coerce(value: str, type_: str) -> Any:
    if type_ == SystemConfigType.INT:
        return int(value)
    if type_ == SystemConfigType.MONEY:
        return Decimal(value)
    if type_ == SystemConfigType.BOOL:
        return value.strip().lower() in {"1", "true", "yes", "on"}
    return value


def get_config(key: str, default: Any = _MISSING) -> Any:
    """Return the typed value for ``key``, cached for 60s.

    Raises :class:`NotFoundError` if the key is absent and no ``default`` given.
    """
    ck = _cache_key(key)
    cached = cache.get(ck, _MISSING)
    if cached is not _MISSING:
        return cached

    try:
        row = SystemConfig.objects.get(key=key)
    except SystemConfig.DoesNotExist:
        if default is not _MISSING:
            return default
        raise NotFoundError(f"SystemConfig key '{key}' is not set.") from None

    value = _coerce(row.value, row.type)
    cache.set(ck, value, _CACHE_TTL)
    return value


def invalidate_config(key: str) -> None:
    """Drop the cached value for ``key`` (called on write)."""
    cache.delete(_cache_key(key))


@receiver(post_save, sender=SystemConfig)
@receiver(post_delete, sender=SystemConfig)
def _invalidate_on_write(sender: type, instance: SystemConfig, **kwargs: Any) -> None:
    invalidate_config(instance.key)
