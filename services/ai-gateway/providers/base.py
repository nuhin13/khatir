"""Provider abstraction shared by every vendor client.

A :class:`Provider` is a thin async HTTP client around one vendor API for one
category (ocr / voice / chat / lease). The router (see ``router.py``) holds the
primary→fallback policy; a provider only knows how to make a single call and
either return a :class:`ProviderResult` or raise :class:`ProviderError`.

The concrete vendor clients (OpenAI, Anthropic, Google, …) are layered on by
later tasks; this module ships the contract plus a generic HTTP provider that
posts the request payload to ``endpoint_url`` and parses a JSON envelope. Tests
substitute in-memory fakes that satisfy the same protocol.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Protocol, runtime_checkable

import httpx


@dataclass(frozen=True, slots=True)
class ProviderConfig:
    """Immutable configuration for a single provider, sourced from Django.

    Mirrors the ``AIProvider`` row (see ``06_database_schema.md``): the gateway
    receives the decrypted/usable fields it needs to make a call.
    """

    provider_key: str
    category: str
    model_name: str = ""
    endpoint_url: str = ""
    api_key: str = ""
    params: dict[str, Any] = field(default_factory=dict)
    is_primary: bool = False
    is_fallback: bool = False
    active: bool = True


@dataclass(frozen=True, slots=True)
class ProviderResult:
    """Successful provider response plus accounting metadata.

    ``tokens_used`` / ``cost_usd`` feed the usage log; ``data`` is the vendor
    payload handed back to the caller.
    """

    data: dict[str, Any]
    tokens_used: int = 0
    cost_usd: float = 0.0


class ProviderError(RuntimeError):
    """Raised when a provider call fails (transport error or vendor error).

    The router catches this to trigger failover and records the failure in the
    usage log.
    """

    def __init__(self, provider_key: str, message: str) -> None:
        self.provider_key = provider_key
        super().__init__(f"[{provider_key}] {message}")


@runtime_checkable
class Provider(Protocol):
    """The single behaviour every vendor client must implement."""

    config: ProviderConfig

    async def call(self, payload: dict[str, Any]) -> ProviderResult:
        """Make one request to the vendor and return a normalised result.

        Must raise :class:`ProviderError` on any failure so the router can fail
        over deterministically.
        """
        ...


class HTTPProvider:
    """Generic JSON-over-HTTP provider used by most vendors.

    POSTs ``payload`` (merged with configured ``params``) to ``endpoint_url``
    with a bearer ``api_key`` and parses a ``{data, tokens_used, cost_usd}``
    JSON envelope. Vendor-specific clients can subclass and override
    :meth:`_build_request` / :meth:`_parse_response`.
    """

    def __init__(self, config: ProviderConfig, client: httpx.AsyncClient) -> None:
        self.config = config
        self._client = client

    def _build_request(self, payload: dict[str, Any]) -> dict[str, Any]:
        body = {**self.config.params, **payload}
        if self.config.model_name:
            body.setdefault("model", self.config.model_name)
        return body

    def _parse_response(self, body: dict[str, Any]) -> ProviderResult:
        return ProviderResult(
            data=body.get("data", body),
            tokens_used=int(body.get("tokens_used", 0)),
            cost_usd=float(body.get("cost_usd", 0.0)),
        )

    async def call(self, payload: dict[str, Any]) -> ProviderResult:
        if not self.config.endpoint_url:
            raise ProviderError(self.config.provider_key, "missing endpoint_url")
        headers = {}
        if self.config.api_key:
            headers["Authorization"] = f"Bearer {self.config.api_key}"
        try:
            resp = await self._client.post(
                self.config.endpoint_url,
                json=self._build_request(payload),
                headers=headers,
            )
            resp.raise_for_status()
        except httpx.HTTPStatusError as exc:
            raise ProviderError(
                self.config.provider_key,
                f"HTTP {exc.response.status_code}",
            ) from exc
        except httpx.HTTPError as exc:
            raise ProviderError(self.config.provider_key, str(exc)) from exc
        try:
            return self._parse_response(resp.json())
        except (ValueError, TypeError) as exc:
            raise ProviderError(self.config.provider_key, f"bad response: {exc}") from exc
