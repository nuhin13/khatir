"""Routing + failover + usage-logging tests for the AI gateway."""

from __future__ import annotations

from collections.abc import Sequence
from typing import Any

import pytest

from providers.base import Provider, ProviderConfig, ProviderError, ProviderResult
from router import (
    AllProvidersFailed,
    NoProviderConfigured,
    ProviderRouter,
    UsageRecord,
)


class FakeProvider:
    """In-memory provider satisfying the Provider protocol."""

    def __init__(self, config: ProviderConfig, *, fail: bool = False) -> None:
        self.config = config
        self._fail = fail
        self.calls: list[dict[str, Any]] = []

    async def call(self, payload: dict[str, Any]) -> ProviderResult:
        self.calls.append(payload)
        if self._fail:
            raise ProviderError(self.config.provider_key, "boom")
        return ProviderResult(data={"ok": self.config.provider_key}, tokens_used=7, cost_usd=0.01)


class RecordingLogger:
    def __init__(self) -> None:
        self.records: list[UsageRecord] = []

    async def log(self, record: UsageRecord) -> None:
        self.records.append(record)


def _cfg(key: str, *, primary: bool = False, fallback: bool = False) -> ProviderConfig:
    return ProviderConfig(
        provider_key=key,
        category="ocr",
        is_primary=primary,
        is_fallback=fallback,
        endpoint_url="https://example.test/ocr",
    )


def _router(
    configs: Sequence[ProviderConfig],
    *,
    fail_keys: set[str] | None = None,
    logger: RecordingLogger | None = None,
) -> tuple[ProviderRouter, RecordingLogger]:
    fail_keys = fail_keys or set()
    logger = logger or RecordingLogger()
    ticks = iter(range(0, 10_000))

    async def source(_category: str) -> Sequence[ProviderConfig]:
        return configs

    def factory(config: ProviderConfig) -> Provider:
        return FakeProvider(config, fail=config.provider_key in fail_keys)

    router = ProviderRouter(
        config_source=source,
        provider_factory=factory,
        usage_logger=logger,
        clock=lambda: float(next(ticks)),
    )
    return router, logger


@pytest.mark.asyncio
async def test_primary_success() -> None:
    configs = [_cfg("primary", primary=True), _cfg("backup", fallback=True)]
    router, logger = _router(configs)

    result = await router.route("ocr", {"q": 1})

    assert result.data == {"ok": "primary"}
    assert len(logger.records) == 1
    rec = logger.records[0]
    assert rec.provider == "primary"
    assert rec.success is True
    assert rec.failover_from is None
    assert rec.tokens_used == 7


@pytest.mark.asyncio
async def test_primary_fail_fallback() -> None:
    configs = [_cfg("primary", primary=True), _cfg("backup", fallback=True)]
    router, logger = _router(configs, fail_keys={"primary"})

    result = await router.route("ocr", {"q": 1})

    assert result.data == {"ok": "backup"}
    assert len(logger.records) == 2
    fail_rec, ok_rec = logger.records
    assert fail_rec.provider == "primary"
    assert fail_rec.success is False
    assert ok_rec.provider == "backup"
    assert ok_rec.success is True
    # The fallback success records which provider it failed over from.
    assert ok_rec.failover_from == "primary"


@pytest.mark.asyncio
async def test_both_fail_raises() -> None:
    configs = [_cfg("primary", primary=True), _cfg("backup", fallback=True)]
    router, logger = _router(configs, fail_keys={"primary", "backup"})

    with pytest.raises(AllProvidersFailed):
        await router.route("ocr", {"q": 1})

    # Usage logged for BOTH failed attempts.
    assert len(logger.records) == 2
    assert all(r.success is False for r in logger.records)
    assert logger.records[1].failover_from == "primary"


@pytest.mark.asyncio
async def test_no_provider_configured_raises() -> None:
    router, logger = _router([])

    with pytest.raises(NoProviderConfigured):
        await router.route("ocr", {"q": 1})

    assert logger.records == []


@pytest.mark.asyncio
async def test_inactive_providers_skipped() -> None:
    active = _cfg("primary", primary=True)
    inactive = ProviderConfig(
        provider_key="dead",
        category="ocr",
        is_fallback=True,
        active=False,
        endpoint_url="https://example.test/ocr",
    )
    router, logger = _router([active, inactive])

    result = await router.route("ocr", {"q": 1})

    assert result.data == {"ok": "primary"}
    assert [r.provider for r in logger.records] == ["primary"]


@pytest.mark.asyncio
async def test_config_cached_within_ttl() -> None:
    calls = {"n": 0}
    configs = [_cfg("primary", primary=True)]

    async def source(_category: str) -> Sequence[ProviderConfig]:
        calls["n"] += 1
        return configs

    def factory(config: ProviderConfig) -> Provider:
        return FakeProvider(config)

    router = ProviderRouter(
        config_source=source,
        provider_factory=factory,
        config_ttl_seconds=60.0,
        clock=lambda: 100.0,  # frozen clock → always within TTL
    )

    await router.route("ocr", {})
    await router.route("ocr", {})

    assert calls["n"] == 1  # second call served from cache
