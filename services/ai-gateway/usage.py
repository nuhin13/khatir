"""Per-call usage logging for the AI gateway (EPIC-14 · T-006).

After every gateway call the :class:`~router.ProviderRouter` emits a
:class:`~router.UsageRecord` (provider, category, tokens, cost, latency,
success, failover_from). This module ships the concrete sink that ferries those
records back to Django so they land in ``AIUsageLog`` (see
``06_database_schema.md`` → AIUsageLog).

The sink is intentionally best-effort: usage telemetry must never break a live
AI call. Transport failures are swallowed by the router's logging hook, and the
factory degrades to :class:`~router.NoOpUsageLogger` when no Django endpoint is
configured (local dev / tests).

Security: the internal token is read from settings and sent only as an
``Authorization`` header — it is never written into a usage record or log line,
and API keys never travel through this path (only accounting metadata does).
"""

from __future__ import annotations

from dataclasses import asdict

import httpx

from config import Settings, get_settings
from router import NoOpUsageLogger, UsageLogger, UsageRecord


class HTTPUsageLogger:
    """Ships :class:`UsageRecord`s to Django's ai-usage ingest endpoint.

    Each record is serialised to JSON and POSTed to ``url``. The optional
    ``internal_token`` is presented as a bearer credential so Django can reject
    calls that do not originate from the gateway. The request is bounded by
    ``timeout`` seconds; the router treats any raised exception as a non-fatal
    logging miss.
    """

    def __init__(
        self,
        url: str,
        client: httpx.AsyncClient,
        *,
        internal_token: str = "",
        timeout: float = 5.0,
    ) -> None:
        self._url = url
        self._client = client
        self._internal_token = internal_token
        self._timeout = timeout

    def _headers(self) -> dict[str, str]:
        headers = {"Content-Type": "application/json"}
        if self._internal_token:
            headers["Authorization"] = f"Bearer {self._internal_token}"
        return headers

    async def log(self, record: UsageRecord) -> None:
        """POST one usage record to Django, raising on transport/HTTP error."""
        resp = await self._client.post(
            self._url,
            json=asdict(record),
            headers=self._headers(),
            timeout=self._timeout,
        )
        resp.raise_for_status()


def build_usage_logger(
    settings: Settings | None = None,
    client: httpx.AsyncClient | None = None,
) -> UsageLogger:
    """Return the usage sink wired from settings.

    Falls back to :class:`NoOpUsageLogger` when usage logging is disabled (no
    ``django_base_url`` configured) so the gateway runs standalone in local dev
    and tests without a Django backend. Supplying ``client`` lets callers share
    a pooled :class:`httpx.AsyncClient`.
    """
    settings = settings or get_settings()
    if not settings.usage_logging_enabled:
        return NoOpUsageLogger()
    return HTTPUsageLogger(
        url=settings.ai_usage_url,
        client=client or httpx.AsyncClient(),
        internal_token=settings.ai_gateway_internal_token,
        timeout=settings.ai_usage_timeout_seconds,
    )
