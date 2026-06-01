"""Tests for the OTP store + service (T-003 test plan §12).

Covers generation, verification success/wrong, expiry, attempt exhaustion, and
resend cooldown. The suite runs against the LocMem cache configured in
``config.settings.test`` (no live Redis needed); ``conftest`` clears it between
tests. All limits are driven by ``SystemConfig`` rows, so tests tune behavior by
writing those rows rather than hardcoding constants.
"""

from __future__ import annotations

import time

import pytest
from django.core.cache import cache

from khatir.accounts import otp
from khatir.accounts.otp import OtpStatus
from khatir.core.models import SystemConfig

pytestmark = pytest.mark.django_db

PHONE = "+8801712345678"


def _set_config(key: str, value: str) -> None:
    SystemConfig.objects.update_or_create(
        key=key, defaults={"value": value, "type": "int"}
    )


@pytest.fixture
def auth_config() -> None:
    """Seed the OTP tunables the migration would provide (T-001)."""
    _set_config("otp_length", "6")
    _set_config("otp_ttl_seconds", "300")
    _set_config("otp_max_attempts", "5")
    _set_config("otp_resend_cooldown_seconds", "60")


def test_generate_and_verify_success(auth_config: None) -> None:
    code = otp.generate_otp(PHONE)
    assert code.isdigit()
    assert len(code) == 6
    result = otp.verify_otp(PHONE, code)
    assert result.status is OtpStatus.SUCCESS
    # A consumed code cannot be reused.
    assert otp.verify_otp(PHONE, code).status is OtpStatus.EXPIRED


def test_generate_respects_configured_length(auth_config: None) -> None:
    _set_config("otp_length", "4")
    code = otp.generate_otp(PHONE)
    assert len(code) == 4


def test_code_stored_hashed_never_plaintext(auth_config: None) -> None:
    code = otp.generate_otp(PHONE)
    stored = cache.get(f"otp:{PHONE}")
    assert stored is not None
    assert "hash" in stored
    assert code not in stored.values()
    assert stored["hash"] != code
    assert len(stored["hash"]) == 64  # HMAC-SHA256 hexdigest


def test_wrong_code(auth_config: None) -> None:
    otp.generate_otp(PHONE)
    result = otp.verify_otp(PHONE, "000000")
    assert result.status is OtpStatus.WRONG
    assert result.remaining_attempts == 4


def test_expired_when_no_code_stored(auth_config: None) -> None:
    # Never issued (or TTL elapsed → key gone) both present as no stored code.
    result = otp.verify_otp(PHONE, "123456")
    assert result.status is OtpStatus.EXPIRED


def test_expired_after_ttl_elapses(auth_config: None) -> None:
    otp.generate_otp(PHONE)
    # Simulate the Redis TTL elapsing by evicting the key.
    cache.delete(f"otp:{PHONE}")
    assert otp.verify_otp(PHONE, "123456").status is OtpStatus.EXPIRED


def test_expired_mid_attempts(auth_config: None) -> None:
    code = otp.generate_otp(PHONE)
    # Force the stored expiry into the past, then a wrong attempt sees it expired.
    payload = cache.get(f"otp:{PHONE}")
    payload["expires_at"] = time.time() - 1
    cache.set(f"otp:{PHONE}", payload, timeout=300)
    assert otp.verify_otp(PHONE, "000000").status is OtpStatus.EXPIRED
    # And the code is burned thereafter.
    assert otp.verify_otp(PHONE, code).status is OtpStatus.EXPIRED


def test_too_many_attempts(auth_config: None) -> None:
    _set_config("otp_max_attempts", "3")
    code = otp.generate_otp(PHONE)
    assert otp.verify_otp(PHONE, "111111").status is OtpStatus.WRONG
    assert otp.verify_otp(PHONE, "222222").status is OtpStatus.WRONG
    # Third wrong attempt exhausts the allowance and burns the code.
    result = otp.verify_otp(PHONE, "333333")
    assert result.status is OtpStatus.TOO_MANY_ATTEMPTS
    assert result.remaining_attempts == 0
    # Even the correct code no longer verifies after exhaustion.
    assert otp.verify_otp(PHONE, code).status is OtpStatus.EXPIRED


def test_wrong_attempt_does_not_extend_ttl(auth_config: None) -> None:
    otp.generate_otp(PHONE)
    original_expires = cache.get(f"otp:{PHONE}")["expires_at"]
    otp.verify_otp(PHONE, "000000")
    assert cache.get(f"otp:{PHONE}")["expires_at"] == original_expires


def test_resend_cooldown(auth_config: None) -> None:
    assert otp.can_resend(PHONE) is True
    otp.generate_otp(PHONE)
    # Cooldown marker is now active → resend blocked.
    assert otp.can_resend(PHONE) is False
    # Once the marker expires (simulated by eviction) resend is allowed again.
    cache.delete(f"otp_cooldown:{PHONE}")
    assert otp.can_resend(PHONE) is True


def test_no_cooldown_when_configured_zero(auth_config: None) -> None:
    _set_config("otp_resend_cooldown_seconds", "0")
    otp.generate_otp(PHONE)
    assert otp.can_resend(PHONE) is True
