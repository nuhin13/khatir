"""OTP delivery helper built on the generic messaging layer (T-004 §3).

``send_otp(phone, code)`` formats the bilingual (bn + en) verification message
and dispatches it over the configured channel with fallback. It is the thin,
OTP-specific seam on top of :mod:`khatir.messaging`; everything channel-related
(selection, fallback, the provider calls) lives in the reusable messaging module
so EPIC-15 extends that rather than this file.

The OTP code is passed straight into the message body and never logged here; the
global PII-masking log filter redacts it from any record the console sender
emits (``04_coding_conventions.md`` §10).
"""

from __future__ import annotations

from khatir.core.config import get_config
from khatir.core.enums import Channel
from khatir.messaging.factory import send_with_fallback


def _format_otp_message(code: str, *, minutes: int) -> str:
    """Return the short bilingual OTP body (bn first, then en) — SMS-length."""
    bn = f"আপনার খাতির ভেরিফিকেশন কোড: {code}। কোডটি {minutes} মিনিট পর্যন্ত বৈধ।"
    en = f"Your Khatir verification code is {code}. Valid for {minutes} minutes."
    return f"{bn}\n{en}"


def send_otp(phone: str, code: str) -> Channel:
    """Format and dispatch the OTP ``code`` to ``phone``.

    The validity window is derived from ``otp_ttl_seconds`` config (rounded up to
    whole minutes). Returns the channel the message was delivered over.
    """
    ttl = int(get_config("otp_ttl_seconds"))
    minutes = max(1, -(-ttl // 60))  # ceil division
    message = _format_otp_message(code, minutes=minutes)
    return send_with_fallback(phone, message)
