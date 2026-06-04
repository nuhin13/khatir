"""Dashboard API — one read endpoint for every landlord metric (T-002 §3/§7).

``GET /api/v1/dashboard?months=N`` returns the full
:class:`~khatir.dashboard.selectors.DashboardMetrics` payload in a single call,
so the mobile dashboard never has to fan out one request per card/chart.

The response is **owner-scoped** — every underlying selector queryset goes
through ``for_user`` (T-001), so a landlord only ever sees their own numbers;
the endpoint is additionally guarded by :class:`IsLandlordOrManager`.

To avoid hammering the database when the app is opened (and the screen mounts
several widgets), the computed payload is cached **per user** for a short TTL
(``§15``: never a global cache key). ``months`` defaults to the
``dashboard_months_default`` ``SystemConfig`` (T-003) and may be overridden by
the query param.
"""

from __future__ import annotations

from typing import Any, cast

from django.core.cache import cache
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from khatir.accounts.models import User
from khatir.core.config import get_config
from khatir.core.permissions import IsLandlordOrManager
from khatir.core.responses import success

from .selectors import get_dashboard
from .serializers import DashboardSerializer

#: Short cache TTL (seconds) — keep numbers fresh enough while smoothing the
#: open-screen burst (``§15``).
_CACHE_TTL = 60
_CACHE_PREFIX = "dashboard:"

#: Fallback when the ``dashboard_months_default`` config row is absent.
_DEFAULT_MONTHS = 6
#: Clamp the param so a client can never request an unbounded series.
_MAX_MONTHS = 24


def _months_default() -> int:
    """The configured default month window (T-003), with a safe fallback."""
    value = get_config("dashboard_months_default", default=_DEFAULT_MONTHS)
    try:
        return max(1, int(value))
    except (TypeError, ValueError):
        return _DEFAULT_MONTHS


def _parse_months(request: Request) -> int:
    """Resolve the ``months`` window: query param, else config default."""
    raw = request.query_params.get("months")
    if raw is None or raw == "":
        return _months_default()
    try:
        months = int(raw)
    except (TypeError, ValueError):
        return _months_default()
    return max(1, min(months, _MAX_MONTHS))


def _cache_key(user: User, months: int) -> str:
    """Per-user cache key (never global) so dashboards never cross-leak."""
    return f"{_CACHE_PREFIX}{user.pk}:{months}"


class DashboardView(APIView):
    """``GET /api/v1/dashboard`` — every dashboard metric, scoped + cached."""

    permission_classes = [IsLandlordOrManager]

    def get(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        user = cast(User, request.user)
        months = _parse_months(request)

        ck = _cache_key(user, months)
        payload = cache.get(ck)
        if payload is None:
            metrics = get_dashboard(user, months=months)
            payload = DashboardSerializer(metrics).data
            cache.set(ck, payload, _CACHE_TTL)
        return success(payload)
