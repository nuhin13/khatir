"""Tests for per-call usage logging (EPIC-14 · T-006).

Verifies the gateway ships each UsageRecord to Django's ai-usage endpoint with
the right payload + auth header, that the no-op fallback engages when no Django
URL is configured, and that the router's best-effort hook swallows transport
failures so a logging outage never breaks a live AI call.
"""

from __future__ import annotations

import json
from collections.abc import Sequence
from typing import Any

import httpx
import pytest

from config import Settings
from providers.base import Provider, ProviderConfig, ProviderResult
from router import NoOpUsageLogger, ProviderRouter, UsageRecord
from usage import HTTPUsageLogger, build_usage_logger


def _record(**overrides: Any) -> UsageRecord:
    base: dict[str, Any] = {
        "provider": "openai",
        "category": "ocr",
        "success": True,
        "latency_ms": 42,
        "tokens_used": 7,
        "cost_usd": 0.01,
        "failover_from": None,
    }
    base.update(overrides)
    return UsageRecord(**base)


@pytest.mark.asyncio
async def test_http_logger_posts_record_with_auth() -> None:
    seen: dict[str, Any] = {}

    def handler(request: httpx.Request) -> httpx.Response:
        seen["url"] = str(request.url)
        seen["auth"] = request.headers.get("Authorization")
        seen["body"] = request.read()
        return httpx.Response(202)

    transport = httpx.MockTransport(handler)
    async with httpx.AsyncClient(transport=transport) as client:
        logger = HTTPUsageLogger(
            url="https://django.test/admin/api/ai-usage",
            client=client,
            internal_token="s3cret",
        )
        await logger.log(_record(tokens_used=11, cost_usd=0.05))

    assert seen["url"] == "https://django.test/admin/api/ai-usage"
    assert seen["auth"] == "Bearer s3cret"
    payload = json.loads(seen["body"])
    assert payload["provider"] == "openai"
    assert payload["category"] == "ocr"
    assert payload["tokens_used"] == 11
    assert payload["cost_usd"] == 0.05
    assert payload["success"] is True


@pytest.mark.asyncio
async def test_http_logger_no_token_omits_auth_header() -> None:
    seen: dict[str, Any] = {}

    def handler(request: httpx.Request) -> httpx.Response:
        seen["auth"] = request.headers.get("Authorization")
        return httpx.Response(200)

    transport = httpx.MockTransport(handler)
    async with httpx.AsyncClient(transport=transport) as client:
        logger = HTTPUsageLogger(url="https://django.test/x", client=client)
        await logger.log(_record())

    assert seen["auth"] is None


@pytest.mark.asyncio
async def test_http_logger_raises_on_error_status() -> None:
    transport = httpx.MockTransport(lambda _req: httpx.Response(500))
    async with httpx.AsyncClient(transport=transport) as client:
        logger = HTTPUsageLogger(url="https://django.test/x", client=client)
        with pytest.raises(httpx.HTTPStatusError):
            await logger.log(_record())


def test_build_logger_falls_back_to_noop_without_django_url() -> None:
    settings = Settings(django_base_url="")
    logger = build_usage_logger(settings=settings)
    assert isinstance(logger, NoOpUsageLogger)


def test_build_logger_returns_http_logger_when_configured() -> None:
    settings = Settings(
        django_base_url="https://django.test/",
        ai_gateway_internal_token="tok",
    )
    logger = build_usage_logger(settings=settings)
    assert isinstance(logger, HTTPUsageLogger)
    assert settings.ai_usage_url == "https://django.test/admin/api/ai-usage"


@pytest.mark.asyncio
async def test_router_logging_failure_does_not_break_call() -> None:
    """A failing usage sink must not propagate out of router.route()."""

    def handler(_req: httpx.Request) -> httpx.Response:
        return httpx.Response(503)

    transport = httpx.MockTransport(handler)

    class _Prov:
        def __init__(self, config: ProviderConfig) -> None:
            self.config = config

        async def call(self, payload: dict[str, Any]) -> ProviderResult:
            return ProviderResult(data={"ok": True}, tokens_used=3, cost_usd=0.0)

    cfg = ProviderConfig(provider_key="p", category="ocr", is_primary=True)

    async def source(_c: str) -> Sequence[ProviderConfig]:
        return [cfg]

    def factory(c: ProviderConfig) -> Provider:
        return _Prov(c)

    async with httpx.AsyncClient(transport=transport) as client:
        logger = HTTPUsageLogger(url="https://django.test/x", client=client)
        router = ProviderRouter(
            config_source=source,
            provider_factory=factory,
            usage_logger=logger,
        )
        result = await router.route("ocr", {"q": 1})

    # Provider result is returned even though every usage POST 503'd.
    assert result.data == {"ok": True}
