"""Admin-portal token primitives — EPIC-11.T-003.

Staff auth is **completely separate** from the customer JWT realm (T-006 /
``rest_framework_simplejwt``). AdminUser is not a Django auth user, so we mint
self-contained HS256 tokens with PyJWT, signed by a dedicated
``ADMIN_JWT_SIGNING_KEY`` (never ``JWT_SIGNING_KEY`` / ``SECRET_KEY`` directly).

Two token shapes share the signing key but are distinguished by their ``typ``
claim so one can never be used where the other is expected:

* ``access`` — issued after a successful login (no MFA) or after verify-mfa.
  Authenticates every admin API call. Carries ``role`` for coarse authz.
* ``mfa``    — short-lived, issued after the password step, exchanged at
  ``verify-mfa`` for an access token. Useless for anything else.

Logout invalidates an access token by recording its ``jti`` in the cache until
its natural expiry (a lightweight blacklist that needs no DB table).
"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta
from typing import Any

import jwt
from django.conf import settings
from django.core.cache import cache

ACCESS_TOKEN_TYPE = "access"
MFA_TOKEN_TYPE = "mfa"
_ALGORITHM = "HS256"
_BLACKLIST_PREFIX = "admin_jwt_blacklist:"


class AdminTokenError(Exception):
    """Raised when an admin token is malformed, expired, wrong-typed, or revoked."""


def _signing_key() -> str:
    return str(settings.ADMIN_JWT_SIGNING_KEY)


def _encode(payload: dict[str, Any]) -> str:
    token = jwt.encode(payload, _signing_key(), algorithm=_ALGORITHM)
    # PyJWT<2 returned bytes; 2.x returns str. Normalise defensively.
    return token.decode("utf-8") if isinstance(token, bytes) else token


def issue_access_token(admin_user_id: int, role: str) -> tuple[str, datetime]:
    """Mint an admin access token. Returns ``(token, expires_at)``.

    The lifetime is capped at the admin session timeout so a token can never
    outlive the session window surfaced to the UI.
    """
    now = datetime.now(UTC)
    lifetime_min = min(
        settings.ADMIN_JWT_ACCESS_LIFETIME_MIN,
        settings.ADMIN_SESSION_TIMEOUT_MINUTES,
    )
    expires_at = now + timedelta(minutes=lifetime_min)
    payload = {
        "typ": ACCESS_TOKEN_TYPE,
        "sub": str(admin_user_id),
        "role": role,
        "jti": uuid.uuid4().hex,
        "iat": int(now.timestamp()),
        "exp": int(expires_at.timestamp()),
    }
    return _encode(payload), expires_at


def issue_mfa_challenge_token(admin_user_id: int) -> str:
    """Mint a short-lived token that carries the user from password to TOTP."""
    now = datetime.now(UTC)
    expires_at = now + timedelta(minutes=settings.ADMIN_MFA_CHALLENGE_LIFETIME_MIN)
    payload = {
        "typ": MFA_TOKEN_TYPE,
        "sub": str(admin_user_id),
        "jti": uuid.uuid4().hex,
        "iat": int(now.timestamp()),
        "exp": int(expires_at.timestamp()),
    }
    return _encode(payload)


def _decode(token: str, *, expected_type: str) -> dict[str, Any]:
    try:
        payload: dict[str, Any] = jwt.decode(
            token,
            _signing_key(),
            algorithms=[_ALGORITHM],
            options={"require": ["exp", "sub", "typ", "jti"]},
        )
    except jwt.PyJWTError as exc:
        raise AdminTokenError(str(exc)) from exc
    if payload.get("typ") != expected_type:
        raise AdminTokenError("Unexpected token type.")
    return payload


def decode_access_token(token: str) -> dict[str, Any]:
    """Validate an access token (signature, expiry, type, not revoked)."""
    payload = _decode(token, expected_type=ACCESS_TOKEN_TYPE)
    if is_blacklisted(payload["jti"]):
        raise AdminTokenError("Token has been revoked.")
    return payload


def decode_mfa_challenge_token(token: str) -> dict[str, Any]:
    """Validate an MFA challenge token (signature, expiry, type)."""
    return _decode(token, expected_type=MFA_TOKEN_TYPE)


def _blacklist_key(jti: str) -> str:
    return f"{_BLACKLIST_PREFIX}{jti}"


def blacklist_access_token(token: str) -> None:
    """Revoke an access token by its ``jti`` until its natural expiry.

    A token that fails to decode is treated as already-dead — logout is
    idempotent and must never error on a stale/garbage token.
    """
    try:
        payload = jwt.decode(
            token,
            _signing_key(),
            algorithms=[_ALGORITHM],
            options={"require": ["exp", "jti"]},
        )
    except jwt.PyJWTError:
        return
    remaining = int(payload["exp"]) - int(datetime.now(UTC).timestamp())
    if remaining > 0:
        cache.set(_blacklist_key(payload["jti"]), True, timeout=remaining)


def is_blacklisted(jti: str) -> bool:
    return bool(cache.get(_blacklist_key(jti)))
