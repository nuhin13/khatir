"""OTP lifecycle store + service (EPIC-01.T-003).

Generate, store (hashed), and verify one-time passcodes, plus resend-cooldown
enforcement. All limits are read from :class:`SystemConfig` via
``khatir.core.config.get_config`` (``03_env_and_config.md`` §4) so behavior is
admin-tunable with no deploy:

* ``otp_length``                  – number of digits in a code
* ``otp_ttl_seconds``             – how long a code stays valid
* ``otp_max_attempts``            – verification attempts before a code is burned
* ``otp_resend_cooldown_seconds`` – minimum gap between code requests

State lives in Redis only (Django's cache backend — RedisCache in prod, LocMem
in tests; see ``settings``). The code is **never** stored in plaintext: only an
HMAC-SHA256 digest (keyed by ``SECRET_KEY``) is held, so a Redis dump alone
cannot reveal a code (T-003 §15). No endpoints, sending, or JWT here (T-005/4/6).
"""

from __future__ import annotations

import hmac
import secrets
import time
from dataclasses import dataclass
from enum import StrEnum
from hashlib import sha256
from typing import Any

from django.conf import settings
from django.core.cache import cache

from khatir.core.config import get_config

_OTP_PREFIX = "otp:"
_COOLDOWN_PREFIX = "otp_cooldown:"


class OtpStatus(StrEnum):
    """Outcome of a verification attempt.

    The endpoint layer (T-005) maps these to the error envelope; the service
    itself stays transport-agnostic.
    """

    SUCCESS = "success"
    WRONG = "wrong"
    EXPIRED = "expired"
    TOO_MANY_ATTEMPTS = "too_many_attempts"


@dataclass(frozen=True)
class VerifyResult:
    """Result of :func:`verify_otp` — a status plus remaining attempts."""

    status: OtpStatus
    remaining_attempts: int = 0


def _otp_key(phone: str) -> str:
    return f"{_OTP_PREFIX}{phone}"


def _cooldown_key(phone: str) -> str:
    return f"{_COOLDOWN_PREFIX}{phone}"


def _hash_code(code: str) -> str:
    """Return the HMAC-SHA256 digest of ``code`` keyed by the server secret.

    Keyed hashing (not a bare digest) means an attacker with a Redis dump still
    cannot brute-force the short numeric code without also holding ``SECRET_KEY``.
    """
    secret = settings.SECRET_KEY.encode("utf-8")
    return hmac.new(secret, code.encode("utf-8"), sha256).hexdigest()


def _generate_code(length: int) -> str:
    """Return a cryptographically random, zero-padded ``length``-digit code."""
    upper = 10**length
    return str(secrets.randbelow(upper)).zfill(length)


def can_resend(phone: str) -> bool:
    """Return ``True`` if no resend cooldown is currently active for ``phone``."""
    return cache.get(_cooldown_key(phone)) is None


def generate_otp(phone: str) -> str:
    """Generate, store (hashed), and return a fresh OTP for ``phone``.

    The code is stored at ``otp:{phone}`` as ``{hash, attempts}`` with a TTL of
    ``otp_ttl_seconds`` and a fresh attempt counter, replacing any existing code.
    A resend-cooldown marker is set for ``otp_resend_cooldown_seconds``.

    The returned plaintext is for the caller to deliver (T-004); it is never
    persisted or logged here.
    """
    length = int(get_config("otp_length"))
    ttl = int(get_config("otp_ttl_seconds"))
    cooldown = int(get_config("otp_resend_cooldown_seconds"))

    code = _generate_code(length)
    payload: dict[str, Any] = {
        "hash": _hash_code(code),
        "attempts": 0,
        "expires_at": time.time() + ttl,
    }
    cache.set(_otp_key(phone), payload, timeout=ttl)
    if cooldown > 0:
        cache.set(_cooldown_key(phone), True, timeout=cooldown)
    return code


def verify_otp(phone: str, code: str) -> VerifyResult:
    """Verify ``code`` against the stored OTP for ``phone``.

    * No stored code (never issued or TTL-expired) → ``EXPIRED``.
    * Correct code → ``SUCCESS``; the code is consumed (deleted).
    * Wrong code → ``WRONG`` with the decremented remaining-attempt count;
      when attempts are exhausted the code is burned and ``TOO_MANY_ATTEMPTS``
      is returned instead.
    """
    max_attempts = int(get_config("otp_max_attempts"))
    key = _otp_key(phone)
    payload: dict[str, Any] | None = cache.get(key)

    if payload is None:
        return VerifyResult(OtpStatus.EXPIRED)

    if hmac.compare_digest(payload["hash"], _hash_code(code)):
        cache.delete(key)
        return VerifyResult(OtpStatus.SUCCESS)

    attempts = int(payload["attempts"]) + 1
    remaining = max_attempts - attempts
    if remaining <= 0:
        cache.delete(key)
        return VerifyResult(OtpStatus.TOO_MANY_ATTEMPTS, remaining_attempts=0)

    # Persist the incremented counter without extending the original TTL: the
    # code must still expire at its original ``expires_at`` regardless of how
    # many wrong attempts were made.
    remaining_ttl = int(payload["expires_at"] - time.time())
    if remaining_ttl <= 0:
        cache.delete(key)
        return VerifyResult(OtpStatus.EXPIRED)
    payload["attempts"] = attempts
    cache.set(key, payload, timeout=remaining_ttl)
    return VerifyResult(OtpStatus.WRONG, remaining_attempts=remaining)
