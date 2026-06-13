"""Tests for the ASR (voice) and chat provider stubs.

Vendor HTTP is mocked with :class:`httpx.MockTransport`; no real API is called,
so no API key ever leaves the test. Each provider is exercised both directly and
through the :class:`~router.ProviderRouter` to confirm it satisfies the Provider
protocol and the router can dispatch its category.
"""

from __future__ import annotations

from collections.abc import Sequence
from typing import Any

import httpx
import pytest

from providers import (
    ASRProvider,
    ChatProvider,
    Provider,
    ProviderConfig,
    ProviderError,
)
from router import ProviderRouter


def _mock_client(handler: Any) -> httpx.AsyncClient:
    return httpx.AsyncClient(transport=httpx.MockTransport(handler))


def _cfg(category: str, key: str = "stub") -> ProviderConfig:
    return ProviderConfig(
        provider_key=key,
        category=category,
        model_name="stub-model",
        endpoint_url="https://vendor.test/v1",
        api_key="never-logged",
        is_primary=True,
    )


# --------------------------------------------------------------------------- ASR


@pytest.mark.asyncio
async def test_asr_normalises_envelope() -> None:
    captured: dict[str, Any] = {}

    def handler(request: httpx.Request) -> httpx.Response:
        captured["body"] = request.content.decode()
        captured["auth"] = request.headers.get("Authorization")
        return httpx.Response(
            200,
            json={
                "data": {"transcript": "ভাড়া পঞ্চাশ হাজার", "fields": {"amount": 50000}},
                "tokens_used": 12,
                "cost_usd": 0.002,
            },
        )

    async with _mock_client(handler) as client:
        provider = ASRProvider(_cfg("voice"), client)
        result = await provider.call({"audio_b64": "AAAA", "context": "rent"})

    assert result.data["transcript"] == "ভাড়া পঞ্চাশ হাজার"
    assert result.data["fields"] == {"amount": 50000}
    assert result.data["language"] == "bn"  # Bangla default applied
    assert result.tokens_used == 12
    # API key is sent as a bearer header, not embedded in logs/body.
    assert captured["auth"] == "Bearer never-logged"
    assert "never-logged" not in captured["body"]


@pytest.mark.asyncio
async def test_asr_defaults_when_vendor_sparse() -> None:
    def handler(_request: httpx.Request) -> httpx.Response:
        return httpx.Response(200, json={"data": {}})

    async with _mock_client(handler) as client:
        provider = ASRProvider(_cfg("voice"), client)
        result = await provider.call({"audio_b64": "AAAA"})

    assert result.data == {"transcript": "", "language": "bn", "fields": {}}


@pytest.mark.asyncio
async def test_asr_rejects_missing_audio() -> None:
    async with _mock_client(lambda r: httpx.Response(200, json={})) as client:
        provider = ASRProvider(_cfg("voice"), client)
        with pytest.raises(ProviderError, match="missing 'audio_b64'"):
            await provider.call({"context": "rent"})


# -------------------------------------------------------------------------- chat


@pytest.mark.asyncio
async def test_chat_normalises_envelope() -> None:
    def handler(_request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            200,
            json={"data": {"reply": "সালাম, কীভাবে সাহায্য করতে পারি?"}, "tokens_used": 9},
        )

    async with _mock_client(handler) as client:
        provider = ChatProvider(_cfg("chat"), client)
        result = await provider.call(
            {"messages": [{"role": "user", "content": "hi"}]}
        )

    assert result.data["reply"] == "সালাম, কীভাবে সাহায্য করতে পারি?"
    assert result.data["role"] == "assistant"
    assert result.tokens_used == 9


@pytest.mark.asyncio
async def test_chat_rejects_empty_messages() -> None:
    async with _mock_client(lambda r: httpx.Response(200, json={})) as client:
        provider = ChatProvider(_cfg("chat"), client)
        with pytest.raises(ProviderError, match="non-empty 'messages'"):
            await provider.call({"messages": []})


# ------------------------------------------------------- router integration smoke


@pytest.mark.asyncio
async def test_router_dispatches_voice_through_asr_stub() -> None:
    def handler(_request: httpx.Request) -> httpx.Response:
        return httpx.Response(200, json={"data": {"transcript": "ok", "fields": {}}})

    configs = [_cfg("voice")]

    async def source(_category: str) -> Sequence[ProviderConfig]:
        return configs

    async with _mock_client(handler) as client:

        def factory(config: ProviderConfig) -> Provider:
            return ASRProvider(config, client)

        router = ProviderRouter(config_source=source, provider_factory=factory)
        result = await router.route("voice", {"audio_b64": "AAAA"})

    assert result.data["transcript"] == "ok"


@pytest.mark.asyncio
async def test_router_dispatches_chat_through_chat_stub() -> None:
    def handler(_request: httpx.Request) -> httpx.Response:
        return httpx.Response(200, json={"data": {"reply": "hello"}})

    configs = [_cfg("chat")]

    async def source(_category: str) -> Sequence[ProviderConfig]:
        return configs

    async with _mock_client(handler) as client:

        def factory(config: ProviderConfig) -> Provider:
            return ChatProvider(config, client)

        router = ProviderRouter(config_source=source, provider_factory=factory)
        result = await router.route(
            "chat", {"messages": [{"role": "user", "content": "yo"}]}
        )

    assert result.data["reply"] == "hello"
