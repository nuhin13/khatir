"""ASR (Bangla voice → fields) provider stub.

Category ``voice`` (see ``enums.md`` → AIProviderCategory). The full speech
pipeline — transcribe Bangla audio, then extract structured rent/expense fields
— is built in EPIC-18. This stub is functional enough for the router to dispatch
``voice`` calls: it validates the audio payload, posts it to the configured
vendor endpoint, and normalises the response into a ``{transcript, fields}``
envelope.

Request payload (from Django / mobile)::

    {"audio_b64": "<base64 wav/ogg>", "language": "bn", "context": "rent"}

Response data::

    {"transcript": "<bangla text>", "language": "bn", "fields": {...}}

The ``fields`` map is whatever the vendor (or, later, our extraction step) pulls
out of the transcript; the stub passes the vendor's parsed fields through
untouched and defaults to an empty map so downstream code never sees ``None``.
"""

from __future__ import annotations

from typing import Any

from providers.base import HTTPProvider, ProviderConfig, ProviderError, ProviderResult

#: Default transcription language for Khatir's primary market (Bangla).
DEFAULT_LANGUAGE = "bn"


class ASRProvider(HTTPProvider):
    """Stub voice→fields provider over the generic HTTP transport.

    Validates that an audio blob is present, fills in the Bangla default
    language, and reshapes the vendor JSON into the gateway's ``voice`` envelope.
    Vendor-specific subclasses can override :meth:`_build_request` /
    :meth:`_parse_response` once EPIC-18 wires real engines.
    """

    def _build_request(self, payload: dict[str, Any]) -> dict[str, Any]:
        audio = payload.get("audio_b64") or payload.get("audio")
        if not audio:
            raise ProviderError(
                self.config.provider_key, "asr payload missing 'audio_b64'"
            )
        body = super()._build_request(payload)
        body.setdefault("language", payload.get("language") or DEFAULT_LANGUAGE)
        return body

    def _parse_response(self, body: dict[str, Any]) -> ProviderResult:
        result = super()._parse_response(body)
        data = dict(result.data)
        data.setdefault("transcript", "")
        data.setdefault("language", DEFAULT_LANGUAGE)
        data.setdefault("fields", {})
        return ProviderResult(
            data=data,
            tokens_used=result.tokens_used,
            cost_usd=result.cost_usd,
        )


def build_asr_provider(config: ProviderConfig, client: Any) -> ASRProvider:
    """Factory helper mirroring the router's :data:`ProviderFactory` shape."""
    return ASRProvider(config, client)
