"""Accounts service layer (business logic; no logic in views — T-003 §2).

Re-exports the OTP lifecycle service so callers (the auth endpoints in T-005)
import account services from one place rather than reaching into ``otp.py``.
"""

from __future__ import annotations

from .otp import (
    OtpStatus,
    VerifyResult,
    can_resend,
    generate_otp,
    verify_otp,
)

__all__ = [
    "OtpStatus",
    "VerifyResult",
    "can_resend",
    "generate_otp",
    "verify_otp",
]
