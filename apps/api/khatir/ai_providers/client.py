"""Thin Django-side client for the AI gateway microservice (EPIC-14.T-007).

All AI provider calls flow through the FastAPI ``ai-gateway`` service rather
than reaching vendor SDKs directly. This module is the Django half: a small,
stateless HTTP client that posts a normalised request to the gateway, presents
the shared internal token, and hands back the gateway's normalised response.

Design notes:

* **No business logic / no routing.** Primary/fallback selection, vendor
  credentials and usage logging all live inside the gateway (EPIC-14.T-003+).
  This client only forwards a category + payload and returns what comes back.
* **Secrets never logged.** The internal token is read from settings and put on
  the ``Authorization`` header; it is never written to a log record. Likewise
  the request/response payloads (which may carry user content) are not logged.
* **Configuration is explicit.** When ``AI_GATEWAY_URL`` is unset the client
  raises :class:`AIGatewayError` with a clear configuration message rather than
  attempting a request to an empty URL.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

import requests
from django.conf import settings

from .enums import AICategory

__all__ = ["AIGatewayError", "AIGatewayResult", "call_gateway"]


class AIGatewayError(Exception):
    """Raised when the gateway is misconfigured or the call fails.

    ``status_code`` carries the HTTP status when the failure was an error
    response from the gateway; it is ``None`` for transport-level failures
    (timeout, connection error) and configuration errors.
    """

    def __init__(self, message: str, *, status_code: int | None = None) -> None:
        super().__init__(message)
        self.message = message
        self.status_code = status_code


@dataclass(frozen=True, slots=True)
class AIGatewayResult:
    """The normalised result returned by the gateway for a single AI call.

    ``data`` is the provider-agnostic payload (e.g. extracted OCR fields, a chat
    completion). ``provider_key`` / ``model_name`` identify which vendor handled
    the call, and ``raw`` keeps the full decoded JSON body for callers that need
    fields not surfaced explicitly here.
    """

    data: dict[str, Any]
    provider_key: str = ""
    model_name: str = ""
    raw: dict[str, Any] = field(default_factory=dict)

    @classmethod
    def from_response(cls, body: dict[str, Any]) -> AIGatewayResult:
        """Build a result from the gateway's decoded JSON body."""
        return cls(
            data=dict(body.get("data") or {}),
            provider_key=str(body.get("provider_key") or ""),
            model_name=str(body.get("model_name") or ""),
            raw=body,
        )


def _gateway_headers() -> dict[str, str]:
    """Build request headers, attaching the internal token when configured."""
    headers = {"Content-Type": "application/json", "Accept": "application/json"}
    token: str = getattr(settings, "AI_GATEWAY_INTERNAL_TOKEN", "") or ""
    if token:
        headers["Authorization"] = f"Bearer {token}"
    return headers


def call_gateway(
    category: AICategory | str,
    payload: dict[str, Any],
    *,
    timeout: float | None = None,
) -> AIGatewayResult:
    """Call the AI gateway for ``category`` with ``payload`` and normalise the result.

    The gateway exposes a per-category endpoint at ``{AI_GATEWAY_URL}/v1/{category}``;
    this posts ``payload`` as JSON with the shared internal token and returns an
    :class:`AIGatewayResult`.

    Raises:
        AIGatewayError: if the gateway URL is unconfigured, the request fails at
            the transport layer, the gateway returns a non-2xx status, or the
            response body is not valid JSON.
    """
    base_url: str = (getattr(settings, "AI_GATEWAY_URL", "") or "").rstrip("/")
    if not base_url:
        raise AIGatewayError(
            "AI_GATEWAY_URL is not configured; cannot reach the AI gateway."
        )

    category_value = category.value if isinstance(category, AICategory) else str(category)
    url = f"{base_url}/v1/{category_value}"
    request_timeout = timeout if timeout is not None else getattr(
        settings, "AI_GATEWAY_TIMEOUT", 30.0
    )

    try:
        response = requests.post(
            url,
            json=payload,
            headers=_gateway_headers(),
            timeout=request_timeout,
        )
    except requests.RequestException as exc:  # transport-level failure
        raise AIGatewayError(f"AI gateway request failed: {exc}") from exc

    if not response.ok:
        raise AIGatewayError(
            f"AI gateway returned HTTP {response.status_code} for category "
            f"'{category_value}'.",
            status_code=response.status_code,
        )

    try:
        body: Any = response.json()
    except ValueError as exc:
        raise AIGatewayError("AI gateway returned a non-JSON response.") from exc

    if not isinstance(body, dict):
        raise AIGatewayError("AI gateway returned an unexpected response shape.")

    return AIGatewayResult.from_response(body)
