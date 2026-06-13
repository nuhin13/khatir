"""Per-email + per-IP throttles for the admin auth endpoints — EPIC-11.T-003.

Mirrors the customer OTP throttles (``accounts.throttling``): two axes per
endpoint — one keyed by the submitted ``email``, one by client IP — so password
and TOTP brute force is capped from either direction. Rates are DRF-scoped and
live in ``REST_FRAMEWORK['DEFAULT_THROTTLE_RATES']`` so ops can tune them
without a deploy; throttle state lives in the cache backend. A hit raises
``Throttled`` (429), which the core handler maps to the ``rate_limited``
envelope.
"""

from __future__ import annotations

from rest_framework.request import Request
from rest_framework.views import APIView

from khatir.accounts.throttling import _ConfigurableRateThrottle


class _EmailScopedThrottle(_ConfigurableRateThrottle):
    """Throttle keyed by the ``email`` in the request body for a given scope.

    Requests without a usable ``email`` are not throttled on this axis — they
    are caught by validation or the IP throttle.
    """

    def get_cache_key(self, request: Request, view: APIView) -> str | None:
        email = None
        if isinstance(request.data, dict):
            raw = request.data.get("email")
            if isinstance(raw, str) and raw.strip():
                email = raw.strip().lower()
        if email is None:
            return None
        return self.cache_format % {"scope": self.scope, "ident": email}


class _IpScopedThrottle(_ConfigurableRateThrottle):
    """Throttle keyed by client IP for a given scope."""

    def get_cache_key(self, request: Request, view: APIView) -> str | None:
        return self.cache_format % {"scope": self.scope, "ident": self.get_ident(request)}


class AdminLoginEmailThrottle(_EmailScopedThrottle):
    scope = "admin_login_email"


class AdminLoginIpThrottle(_IpScopedThrottle):
    scope = "admin_login_ip"


class AdminMfaIpThrottle(_IpScopedThrottle):
    scope = "admin_mfa_ip"
