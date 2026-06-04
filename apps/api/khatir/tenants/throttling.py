"""Per-user throttle for the cost-sensitive OCR endpoint (EPIC-04.T-005).

``POST /tenants/ocr`` calls an external OCR provider on every request, so each
call has a real money cost. This throttle caps how often a single authenticated
landlord/manager can hit it, keyed by user id, blunting accidental loops and
abuse without affecting other users.

The rate is DRF-scoped (``tenant_ocr``), so it lives in
``REST_FRAMEWORK["DEFAULT_THROTTLE_RATES"]`` and is ops-tunable from settings /
env with no code change. State lives in the cache backend (Redis in prod,
LocMem in tests), like every other rate-limit primitive. When the limit is hit
DRF raises ``Throttled`` (HTTP 429); the core exception handler already maps that
to the standard ``rate_limited`` envelope, so no extra wiring is needed.
"""

from __future__ import annotations

from rest_framework.request import Request
from rest_framework.settings import api_settings
from rest_framework.throttling import SimpleRateThrottle
from rest_framework.views import APIView


class _PerUserScopedThrottle(SimpleRateThrottle):
    """Base: cap calls per authenticated user for a settings-tunable scope.

    Shared by the OCR and voice endpoints — both call paid external providers
    (OCR/ASR) on every request, so each is rate-limited per user, keyed by id.
    """

    def get_rate(self) -> str | None:
        """Read the scope's rate from live settings.

        ``SimpleRateThrottle.THROTTLE_RATES`` is bound at import time, so it does
        not reflect ``override_settings`` (tests) or a runtime reload. Reading
        ``api_settings`` here keeps the rate current and tunable.
        """
        rates = api_settings.DEFAULT_THROTTLE_RATES
        if self.scope is not None and self.scope in rates:
            rate = rates[self.scope]
            return str(rate) if rate is not None else None
        return super().get_rate()

    def get_cache_key(self, request: Request, view: APIView) -> str | None:
        user = request.user
        if not (user and user.is_authenticated):
            return None  # unauthenticated requests are rejected by permissions
        return self.cache_format % {"scope": self.scope, "ident": user.pk}


class OcrUserThrottle(_PerUserScopedThrottle):
    """Cap OCR extractions per authenticated user (external provider cost)."""

    scope = "tenant_ocr"


class VoiceUserThrottle(_PerUserScopedThrottle):
    """Cap voice extractions per authenticated user (external ASR cost)."""

    scope = "tenant_voice"
