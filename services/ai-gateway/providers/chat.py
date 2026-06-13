"""Chat (assistant) provider stub.

Category ``chat`` (see ``enums.md`` → AIProviderCategory). The full conversational
assistant is built in EPIC-23. This stub is functional enough for the router to
dispatch ``chat`` calls: it validates the messages payload, forwards it to the
configured vendor endpoint, and normalises the response into a ``{reply, role}``
envelope.

Request payload (from Django)::

    {"messages": [{"role": "user", "content": "..."}], "language": "bn"}

Response data::

    {"reply": "<assistant text>", "role": "assistant"}

The stub passes any extra vendor params through via the base transport and only
guarantees the envelope shape so downstream callers (and tests) are stable while
the real prompt/tooling lands later.
"""

from __future__ import annotations

from typing import Any

from providers.base import HTTPProvider, ProviderConfig, ProviderError, ProviderResult

#: Default assistant language for Khatir's primary market (Bangla).
DEFAULT_LANGUAGE = "bn"


class ChatProvider(HTTPProvider):
    """Stub chat provider over the generic HTTP transport.

    Validates that a non-empty ``messages`` list is supplied, defaults the
    language to Bangla, and reshapes the vendor JSON into the gateway's ``chat``
    envelope. Vendor-specific subclasses override :meth:`_build_request` /
    :meth:`_parse_response` once EPIC-23 wires real models.
    """

    def _build_request(self, payload: dict[str, Any]) -> dict[str, Any]:
        messages = payload.get("messages")
        if not isinstance(messages, list) or not messages:
            raise ProviderError(
                self.config.provider_key,
                "chat payload requires a non-empty 'messages' list",
            )
        body = super()._build_request(payload)
        body.setdefault("language", payload.get("language") or DEFAULT_LANGUAGE)
        return body

    def _parse_response(self, body: dict[str, Any]) -> ProviderResult:
        result = super()._parse_response(body)
        data = dict(result.data)
        data.setdefault("reply", "")
        data.setdefault("role", "assistant")
        return ProviderResult(
            data=data,
            tokens_used=result.tokens_used,
            cost_usd=result.cost_usd,
        )


def build_chat_provider(config: ProviderConfig, client: Any) -> ChatProvider:
    """Factory helper mirroring the router's :data:`ProviderFactory` shape."""
    return ChatProvider(config, client)
