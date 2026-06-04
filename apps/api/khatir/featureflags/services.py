"""Feature-flag services — EPIC-13.T-002.

Business logic for the admin flag CRUD/toggle endpoints and the public-config
``flags`` block lives here; views only validate + serialize + delegate.

The public ``flags`` dict surfaced via ``/config/public`` is cached for 60s and
explicitly invalidated whenever a flag is created, updated, or toggled, so
clients observe changes well within the <60s propagation budget (task §1).
"""

from __future__ import annotations

from typing import Any

import pyotp
from django.conf import settings
from django.core.cache import cache
from django.db import transaction

from khatir.admin_portal.audit import admin_audit
from khatir.admin_portal.models import AdminUser
from khatir.core.encryption import decrypt

from .enums import FlagScope, KillSwitchAction
from .models import FeatureFlag, KillSwitchEvent

#: Cache key for the public ``flags`` dict served by ``/config/public``.
PUBLIC_FLAGS_CACHE_KEY = "featureflags:public"
_CACHE_TTL = 60  # seconds — matches the <60s client propagation budget.

#: The 5 named kill-switches (seeded as global flags in T-004), in display
#: order. ``master_kill_switch`` is the global last-resort switch.
KILL_SWITCH_KEYS: tuple[str, ...] = (
    "warnings_feature",
    "reviews_feature",
    "history_flags_feature",
    "free_text_feature",
    "master_kill_switch",
)


class KillSwitchMFAError(Exception):
    """Raised when a kill-switch toggle fails fresh MFA re-confirmation."""


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


# ── Kill-switches (EPIC-13.T-003) ───────────────────────────────────────────


def get_kill_switches() -> list[FeatureFlag]:
    """Return the 5 named kill-switch flags in canonical display order.

    Any switch missing from the DB (e.g. an un-seeded test DB) is simply
    omitted; callers see only the rows that exist.
    """
    by_key = {
        flag.key: flag
        for flag in FeatureFlag.objects.filter(key__in=KILL_SWITCH_KEYS)
    }
    return [by_key[key] for key in KILL_SWITCH_KEYS if key in by_key]


def _verify_fresh_mfa(admin_user: AdminUser, code: str) -> None:
    """Require a fresh TOTP re-confirmation, raising on any failure.

    Re-confirmation is mandatory even within an active session (task §15 —
    intentional friction). When ``ADMIN_MFA_REQUIRED`` is off (and the account
    has no TOTP secret) the check is skipped so non-MFA dev/test accounts can
    still operate; an account WITH a secret is always re-confirmed.
    """
    if not admin_user.totp_secret_enc:
        if settings.ADMIN_MFA_REQUIRED:
            raise KillSwitchMFAError(
                "MFA is not configured for this account; cannot re-confirm."
            )
        return

    secret = decrypt(admin_user.totp_secret_enc)
    # valid_window=1 tolerates a single 30s step of clock skew either side.
    if not pyotp.TOTP(secret).verify(code.strip(), valid_window=1):
        raise KillSwitchMFAError("The MFA code is invalid. Please try again.")


@transaction.atomic
def toggle_kill_switch(
    *,
    key: str,
    admin_user: AdminUser,
    mfa_code: str,
    reason: str,
    lawyer_reference: str = "",
    ip: str | None = None,
) -> FeatureFlag:
    """Re-confirm MFA, flip the named kill-switch, record an immutable event.

    The switch is "live" while ``enabled`` is ``True``; flipping to ``False``
    KILLS the feature. Records a :class:`KillSwitchEvent` (``disable`` when the
    feature is being killed, ``enable`` when restored), audits the actor, and
    busts the public-config cache for instant propagation (<60s). The whole
    operation is atomic so a failed event write never leaves a flipped flag.

    Raises :class:`KillSwitchMFAError` (MFA failure) — the view maps it to 403.
    """
    _verify_fresh_mfa(admin_user, mfa_code)

    flag = FeatureFlag.objects.select_for_update().get(key=key)
    before = flag.enabled
    flag.enabled = not before
    flag.updated_by = admin_user
    flag.save(update_fields=["enabled", "updated_by", "updated_at"])

    # enabled True->False kills the feature (disable); False->True restores it.
    action = (
        KillSwitchAction.DISABLE if before else KillSwitchAction.ENABLE
    )
    KillSwitchEvent.objects.create(
        switch_key=key,
        action=action,
        reason=reason,
        admin_user=admin_user,
        lawyer_reference=lawyer_reference,
    )

    admin_audit(
        admin_user=admin_user,
        action="kill_switch.toggle",
        entity=flag,
        before={"enabled": before},
        after={"enabled": flag.enabled},
        ip=ip,
        reason=reason,
    )
    _bust_cache()
    return flag
