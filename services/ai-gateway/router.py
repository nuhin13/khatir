"""Provider-agnostic routing with primary→fallback failover.

For a given category (ocr / voice / chat / lease) the :class:`ProviderRouter`
asks a config source for the active providers, tries the primary, and — if it
raises :class:`~providers.base.ProviderError` — tries the fallback. Every call
(success or failure) is recorded through a pluggable usage-logging hook so the
gateway can forward usage back to Django's ``AIUsageLog``.

Design notes
------------
* The router is provider-agnostic: it only sees the :class:`Provider` protocol
  and :class:`ProviderConfig`, never a concrete vendor.
* Provider config is fetched through a :class:`ConfigSource` callable and cached
  for ``config_ttl_seconds`` (default 60s, env-overridable per task §15) so a
  burst of calls does not hammer Django.
* Usage is *always* logged, even when both providers fail, so failover and
  outages are observable.
"""

from __future__ import annotations

import time
from collections.abc import Awaitable, Callable, Sequence
from dataclasses import dataclass
from typing import Any, Protocol

from providers.base import Provider, ProviderConfig, ProviderError, ProviderResult

#: Returns the ordered list of active providers for a category (primary first).
ConfigSource = Callable[[str], Awaitable[Sequence[ProviderConfig]]]


@dataclass(frozen=True, slots=True)
class UsageRecord:
    """One row destined for Django's ``AIUsageLog``.

    Field names mirror the schema (``06_database_schema.md`` → AIUsageLog):
    provider, category, request_count, tokens_used, cost_usd, success,
    latency_ms, failover_from.
    """

    provider: str
    category: str
    success: bool
    latency_ms: int
    request_count: int = 1
    tokens_used: int = 0
    cost_usd: float = 0.0
    failover_from: str | None = None
    error: str | None = None


class UsageLogger(Protocol):
    """Sink for usage records (HTTP to Django, queue, stdout, …)."""

    async def log(self, record: UsageRecord) -> None: ...


class NoOpUsageLogger:
    """Default logger that discards records (used when none is wired in)."""

    async def log(self, record: UsageRecord) -> None:  # noqa: D102 - protocol impl
        return None


class NoProviderConfigured(RuntimeError):
    """No active provider exists for the requested category."""


class AllProvidersFailed(RuntimeError):
    """Every configured provider (primary and fallback) failed."""

    def __init__(self, category: str, last_error: ProviderError) -> None:
        self.category = category
        self.last_error = last_error
        super().__init__(f"all providers failed for category '{category}': {last_error}")


# Builds a live Provider from its config. Injected so tests can supply fakes
# and production can supply real HTTP clients.
ProviderFactory = Callable[[ProviderConfig], Provider]


class _CacheEntry:
    __slots__ = ("configs", "expires_at")

    def __init__(self, configs: Sequence[ProviderConfig], expires_at: float) -> None:
        self.configs = configs
        self.expires_at = expires_at


class ProviderRouter:
    """Routes one logical AI call to a primary provider, then a fallback."""

    def __init__(
        self,
        config_source: ConfigSource,
        provider_factory: ProviderFactory,
        usage_logger: UsageLogger | None = None,
        config_ttl_seconds: float = 60.0,
        clock: Callable[[], float] = time.monotonic,
    ) -> None:
        self._config_source = config_source
        self._provider_factory = provider_factory
        self._usage_logger: UsageLogger = usage_logger or NoOpUsageLogger()
        self._config_ttl_seconds = config_ttl_seconds
        self._clock = clock
        self._cache: dict[str, _CacheEntry] = {}

    async def _providers_for(self, category: str) -> Sequence[ProviderConfig]:
        now = self._clock()
        entry = self._cache.get(category)
        if entry is not None and entry.expires_at > now:
            return entry.configs
        configs = [c for c in await self._config_source(category) if c.active]
        self._cache[category] = _CacheEntry(configs, now + self._config_ttl_seconds)
        return configs

    @staticmethod
    def _ordered(configs: Sequence[ProviderConfig]) -> list[ProviderConfig]:
        """Primary first, then fallback, then any remaining active providers."""
        primary = [c for c in configs if c.is_primary]
        fallback = [c for c in configs if c.is_fallback and not c.is_primary]
        rest = [c for c in configs if not c.is_primary and not c.is_fallback]
        return [*primary, *fallback, *rest]

    async def _record(self, record: UsageRecord) -> None:
        # Never let a logging failure mask the provider result.
        try:
            await self._usage_logger.log(record)
        except Exception:  # noqa: BLE001 - logging is best-effort
            pass

    async def route(self, category: str, payload: dict[str, Any]) -> ProviderResult:
        """Execute ``payload`` against ``category``, failing over as needed.

        Raises :class:`NoProviderConfigured` when nothing is active for the
        category, or :class:`AllProvidersFailed` when every provider errors.
        """
        ordered = self._ordered(list(await self._providers_for(category)))
        if not ordered:
            raise NoProviderConfigured(category)

        last_error: ProviderError | None = None
        failed_from: str | None = None

        for config in ordered:
            provider = self._provider_factory(config)
            started = self._clock()
            try:
                result = await provider.call(payload)
            except ProviderError as exc:
                latency_ms = int((self._clock() - started) * 1000)
                await self._record(
                    UsageRecord(
                        provider=config.provider_key,
                        category=category,
                        success=False,
                        latency_ms=latency_ms,
                        failover_from=failed_from,
                        error=str(exc),
                    )
                )
                last_error = exc
                failed_from = config.provider_key
                continue

            latency_ms = int((self._clock() - started) * 1000)
            await self._record(
                UsageRecord(
                    provider=config.provider_key,
                    category=category,
                    success=True,
                    latency_ms=latency_ms,
                    tokens_used=result.tokens_used,
                    cost_usd=result.cost_usd,
                    failover_from=failed_from,
                )
            )
            return result

        assert last_error is not None  # noqa: S101 - guarded by `ordered` non-empty
        raise AllProvidersFailed(category, last_error)
