"""Feature-flag services — EPIC-13.T-002.

Business logic for the admin flag CRUD/toggle endpoints and the public-config
``flags`` block lives here; views only validate + serialize + delegate.

The public ``flags`` dict surfaced via ``/config/public`` is cached for 60s and
explicitly invalidated whenever a flag is created, updated, or toggled, so
clients observe changes well within the <60s propagation budget (task §1).
"""

from __future__ import annotations

from typing import Any

from django.core.cache import cache

from khatir.admin_portal.audit import admin_audit
from khatir.admin_portal.models import AdminUser

from .enums import FlagScope
from .models import FeatureFlag

#: Cache key for the public ``flags`` dict served by ``/config/public``.
PUBLIC_FLAGS_CACHE_KEY = "featureflags:public"
_CACHE_TTL = 60  # seconds — matches the <60s client propagation budget.


def public_flags() -> dict[str, bool]:
    """Return ``{key: enabled}`` for every **global** flag, cached for 60s.

    Only ``scope=global`` flags are exposed publicly — role/user-scoped flags
    are resolved per-principal and never leak through the anonymous config.
    The result is cached and busted on any flag write (see :func:`_bust_cache`).
    """
    cached = cache.get(PUBLIC_FLAGS_CACHE_KEY)
    if cached is not None:
        return cached

    flags = dict(
        FeatureFlag.objects.filter(scope=FlagScope.GLOBAL).values_list(
            "key", "enabled"
        )
    )
    cache.set(PUBLIC_FLAGS_CACHE_KEY, flags, _CACHE_TTL)
    return flags


def _bust_cache() -> None:
    """Drop the cached public-flags dict so the next read rebuilds it."""
    cache.delete(PUBLIC_FLAGS_CACHE_KEY)


def toggle_flag(
    *,
    flag: FeatureFlag,
    admin_user: AdminUser,
    ip: str | None = None,
) -> FeatureFlag:
    """Flip ``flag.enabled``, record ``updated_by``, audit, and bust the cache.

    Returns the refreshed flag. The audit entry captures the before/after
    ``enabled`` state for the acting admin (task §14 — audited).
    """
    before = flag.enabled
    flag.enabled = not before
    flag.updated_by = admin_user
    flag.save(update_fields=["enabled", "updated_by", "updated_at"])

    admin_audit(
        admin_user=admin_user,
        action="feature_flag.toggle",
        entity=flag,
        before={"enabled": before},
        after={"enabled": flag.enabled},
        ip=ip,
        reason=f"Toggled flag '{flag.key}' {'on' if flag.enabled else 'off'}.",
    )
    _bust_cache()
    return flag


def record_flag_write(
    *,
    flag: FeatureFlag,
    admin_user: AdminUser,
    action: str,
    before: dict[str, Any] | None,
    after: dict[str, Any] | None,
    ip: str | None = None,
) -> None:
    """Audit a create/update flag write and bust the public-flags cache."""
    flag.updated_by = admin_user
    flag.save(update_fields=["updated_by", "updated_at"])
    admin_audit(
        admin_user=admin_user,
        action=action,
        entity=flag,
        before=before,
        after=after,
        ip=ip,
    )
    _bust_cache()
