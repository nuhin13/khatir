"""Per-phone + per-IP throttles for the OTP auth endpoints (EPIC-01.T-007).

These sit *in front of* the views, above the per-code attempt cap (T-003) and
the per-phone resend cooldown (T-001/T-003): the cooldown spaces out individual
requests, while these throttles cap the total volume in a window — blunting
SMS/WhatsApp cost bombs and OTP brute force from a single phone or IP.

Each endpoint gets two throttles — one keyed by the submitted ``phone`` and one
by client IP — so abuse from either axis is curbed independently. Rates are
DRF-scoped, so they live in ``REST_FRAMEWORK["DEFAULT_THROTTLE_RATES"]`` and are
admin/ops-tunable from settings with no code change (T-007 §2). Throttle state
lives in the cache backend (Redis in prod, LocMem in tests) like every other
auth rate-limit primitive in this app.

When a limit is hit, DRF raises ``rest_framework.exceptions.Throttled`` (HTTP
429); the core exception handler already maps that status to the standard
``rate_limited`` envelope (``core/exceptions.py``), so no extra wiring is needed.
"""

from __future__ import annotations

import re

from rest_framework.request import Request
from rest_framework.settings import api_settings
from rest_framework.throttling import SimpleRateThrottle
from rest_framework.views import APIView

# DRF's built-in parse_rate only accepts a bare unit period ("s"/"m"/"h"/"d").
# We extend it with an optional integer multiplier ("10min", "10m") so windows
# like "10 requests per 10 minutes" (T-007 §15) are expressible in settings.
_RATE_RE = re.compile(r"^\s*(\d+)\s*/\s*(\d*)\s*([a-zA-Z]+)\s*$")
_PERIOD_SECONDS = {"s": 1, "m": 60, "min": 60, "h": 3600, "hour": 3600, "d": 86400}


class _ConfigurableRateThrottle(SimpleRateThrottle):
    """``SimpleRateThrottle`` whose rate string accepts a period multiplier.

    Supports the DRF forms (``5/hour``, ``10/m``) plus a leading count on the
    period (``10/10min`` → 10 requests / 600s), so the auth limits read exactly
    as specified without losing settings-tunability.
    """

    def get_rate(self) -> str | None:
        """Read the scope's rate from live settings.

        ``SimpleRateThrottle.THROTTLE_RATES`` is bound at import time, so it does
        not reflect ``override_settings`` (tests) or any runtime settings reload.
        Reading ``api_settings`` here keeps the rate current and tunable.
        """
        rates = api_settings.DEFAULT_THROTTLE_RATES
        if self.scope is not None and self.scope in rates:
            rate = rates[self.scope]
            return str(rate) if rate is not None else None
        return super().get_rate()

    def parse_rate(self, rate: str | None) -> tuple[int | None, int | None]:
        if rate is None:
            return (None, None)
        match = _RATE_RE.match(rate)
        if match is None:  # fall back to DRF's parser for anything unexpected
            return super().parse_rate(rate)
        num_requests = int(match.group(1))
        multiplier = int(match.group(2)) if match.group(2) else 1
        unit = match.group(3).lower()
        if unit not in _PERIOD_SECONDS:
            unit = unit[0]  # tolerate "hour"/"minute" by first letter, like DRF
        duration = _PERIOD_SECONDS[unit] * multiplier
        return (num_requests, duration)


class _PhoneScopedThrottle(_ConfigurableRateThrottle):
    """Throttle keyed by the ``phone`` in the request body for a given scope.

    Subclasses set ``scope`` (which selects the rate from
    ``DEFAULT_THROTTLE_RATES``). Requests without a usable ``phone`` are not
    throttled on this axis — they are caught by validation or the IP throttle.
    """

    def get_cache_key(self, request: Request, view: APIView) -> str | None:
        phone = None
        if isinstance(request.data, dict):
            raw = request.data.get("phone")
            if isinstance(raw, str) and raw.strip():
                phone = raw.strip()
        if phone is None:
            return None
        return self.cache_format % {"scope": self.scope, "ident": phone}


class _IpScopedThrottle(_ConfigurableRateThrottle):
    """Throttle keyed by client IP for a given scope (cost-bomb / brute-force)."""

    def get_cache_key(self, request: Request, view: APIView) -> str | None:
        ident = self.get_ident(request)
        return self.cache_format % {"scope": self.scope, "ident": ident}


class RequestOtpPhoneThrottle(_PhoneScopedThrottle):
    """Cap OTP requests per phone (SMS/WhatsApp cost protection)."""

    scope = "request_otp_phone"


class RequestOtpIpThrottle(_IpScopedThrottle):
    """Cap OTP requests per IP (cost protection across many phones)."""

    scope = "request_otp_ip"


class VerifyOtpPhoneThrottle(_PhoneScopedThrottle):
    """Cap verify attempts per phone (brute-force protection, above T-003 cap)."""

    scope = "verify_otp_phone"


class VerifyOtpIpThrottle(_IpScopedThrottle):
    """Cap verify attempts per IP (brute-force protection across many phones)."""

    scope = "verify_otp_ip"
