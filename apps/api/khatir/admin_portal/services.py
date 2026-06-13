"""Admin auth business logic — EPIC-11.T-003.

Views validate input and serialize output; all decision-making, error-raising,
token issuance, and audit live here. The flow:

1. :func:`admin_login` — verify email+password against a non-disabled account.
   If the account has a TOTP secret and ``ADMIN_MFA_REQUIRED`` is on, return an
   ``mfa_required`` challenge instead of a token. Otherwise issue an access
   token directly (first-run / pre-MFA-setup accounts).
2. :func:`admin_verify_mfa` — exchange a challenge token + a valid TOTP code for
   an admin access token, stamping ``last_login_at``.
3. :func:`admin_logout` — revoke the caller's access token.

Every login, failed attempt, and logout is recorded via
:func:`khatir.admin_portal.audit.admin_audit`. Failures raise the typed
``AuthInvalidError`` with a deliberately generic message so the response does
not reveal whether the email exists or which factor failed.
"""

from __future__ import annotations

from datetime import datetime
from typing import Any

import pyotp
from django.conf import settings
from django.contrib.auth.hashers import check_password
from django.utils import timezone

from khatir.core.encryption import decrypt
from khatir.core.exceptions import AuthInvalidError

from .audit import admin_audit
from .auth_tokens import (
    AdminTokenError,
    blacklist_access_token,
    decode_mfa_challenge_token,
    issue_access_token,
    issue_mfa_challenge_token,
)
from .models import AdminUser

# Deliberately uniform so the caller cannot distinguish "no such email", "wrong
# password", "wrong code", or "disabled account" from the error envelope.
_GENERIC_AUTH_FAILURE = "Invalid credentials."


def _mfa_enabled(admin_user: AdminUser) -> bool:
    """An account requires MFA when it has a TOTP secret and the flag is on."""
    return bool(admin_user.totp_secret_enc) and bool(settings.ADMIN_MFA_REQUIRED)


def admin_login(*, email: str, password: str, ip: str | None) -> dict[str, Any]:
    """Verify password; return either an ``mfa_required`` challenge or a token.

    Returns one of::

        {"mfa_required": True, "mfa_token": "<jwt>"}
        {"mfa_required": False, "access": "<jwt>", "expires_at": "...", ...}
    """
    email = email.strip().lower()
    try:
        admin_user = AdminUser.objects.get(email=email)
    except AdminUser.DoesNotExist:
        admin_audit(admin_user=None, action="admin_auth.login_failed", ip=ip,
                    reason=f"unknown email: {email}")
        raise AuthInvalidError(_GENERIC_AUTH_FAILURE) from None

    if admin_user.disabled:
        admin_audit(admin_user=admin_user, action="admin_auth.login_failed", ip=ip,
                    reason="account disabled")
        raise AuthInvalidError(_GENERIC_AUTH_FAILURE)

    if not check_password(password, admin_user.password_hash):
        admin_audit(admin_user=admin_user, action="admin_auth.login_failed", ip=ip,
                    reason="wrong password")
        raise AuthInvalidError(_GENERIC_AUTH_FAILURE)

    if _mfa_enabled(admin_user):
        admin_audit(admin_user=admin_user, action="admin_auth.mfa_challenged", ip=ip)
        return {
            "mfa_required": True,
            "mfa_token": issue_mfa_challenge_token(admin_user.pk),
        }

    return {"mfa_required": False, **_complete_login(admin_user, ip=ip)}


def admin_verify_mfa(*, mfa_token: str, code: str, ip: str | None) -> dict[str, Any]:
    """Exchange a challenge token + TOTP code for an admin access token."""
    try:
        payload = decode_mfa_challenge_token(mfa_token)
    except AdminTokenError as exc:
        raise AuthInvalidError("The MFA challenge has expired. Please log in again.") from exc

    try:
        admin_user = AdminUser.objects.get(pk=int(payload["sub"]))
    except (AdminUser.DoesNotExist, ValueError, KeyError) as exc:
        raise AuthInvalidError(_GENERIC_AUTH_FAILURE) from exc

    if admin_user.disabled:
        admin_audit(admin_user=admin_user, action="admin_auth.mfa_failed", ip=ip,
                    reason="account disabled")
        raise AuthInvalidError(_GENERIC_AUTH_FAILURE)

    if not admin_user.totp_secret_enc:
        # Should not happen (challenge only issued when a secret exists), but be safe.
        admin_audit(admin_user=admin_user, action="admin_auth.mfa_failed", ip=ip,
                    reason="no TOTP secret configured")
        raise AuthInvalidError(_GENERIC_AUTH_FAILURE)

    secret = decrypt(admin_user.totp_secret_enc)
    # valid_window=1 tolerates a single 30s step of clock skew either side.
    if not pyotp.TOTP(secret).verify(code.strip(), valid_window=1):
        admin_audit(admin_user=admin_user, action="admin_auth.mfa_failed", ip=ip,
                    reason="wrong TOTP code")
        raise AuthInvalidError(_GENERIC_AUTH_FAILURE)

    return _complete_login(admin_user, ip=ip)


def _complete_login(admin_user: AdminUser, *, ip: str | None) -> dict[str, Any]:
    """Issue an access token, stamp ``last_login_at``, audit, and shape output."""
    token, expires_at = issue_access_token(admin_user.pk, admin_user.role)
    admin_user.last_login_at = timezone.now()
    admin_user.save(update_fields=["last_login_at", "updated_at"])
    admin_audit(admin_user=admin_user, action="admin_auth.login_success", ip=ip)
    return {
        "access": token,
        "expires_at": _iso(expires_at),
        "session_timeout_minutes": settings.ADMIN_SESSION_TIMEOUT_MINUTES,
        "admin": admin_user,
    }


def admin_logout(*, admin_user: AdminUser, token: str, ip: str | None) -> None:
    """Revoke the supplied access token and audit the logout."""
    blacklist_access_token(token)
    admin_audit(admin_user=admin_user, action="admin_auth.logout", ip=ip)


def _iso(value: datetime) -> str:
    return value.isoformat()
