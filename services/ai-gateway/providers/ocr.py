"""Concrete OCR provider client (T-004 §1/§2).

:class:`GoogleVisionOcrProvider` is a thin async HTTP client around the Google
Cloud Vision ``images:annotate`` REST API (or any configured OCR backend that
speaks the same envelope). It accepts raw image bytes and returns a normalized
:class:`ExtractedTenant` payload — the single provider-agnostic shape every
OCR/ASR backend yields (mirrors ``khatir.tenants.extraction.dto.ExtractedTenant``
on the Django side).

The provider subclasses :class:`~providers.base.HTTPProvider` so the
:class:`~router.ProviderRouter` can treat it interchangeably with any other
vendor client. The API key comes from the ``AIProvider`` config
(:class:`~providers.base.ProviderConfig.api_key`) — never hardcoded, never
logged. Only the *normalized* DTO crosses the call boundary; the raw Vision
payload is parsed and discarded inside this module (privacy, self-review §14).
"""

from __future__ import annotations

import base64
import re
from dataclasses import asdict, dataclass, field
from typing import Any

import httpx

from providers.base import HTTPProvider, ProviderConfig, ProviderError, ProviderResult

#: Default Google Cloud Vision REST endpoint (overridable via provider config).
GOOGLE_VISION_ENDPOINT = "https://vision.googleapis.com/v1/images:annotate"

#: Fields the OCR layer normalizes into; mirrors the Django ExtractedTenant DTO.
_FIELDS = ("name", "nid_number", "dob", "address")

#: ISO-8601 calendar date, e.g. ``1990-04-23`` (DTO promises ``dob`` as a date).
_ISO_DATE = re.compile(r"\b(\d{4})-(\d{2})-(\d{2})\b")
#: ``DD/MM/YYYY`` or ``DD-MM-YYYY`` as printed on many ID cards.
_DMY_DATE = re.compile(r"\b(\d{2})[/-](\d{2})[/-](\d{4})\b")

#: Labels (case-insensitive) used to locate a field on a tokenized ID card line.
_LABELS: dict[str, tuple[str, ...]] = {
    "name": ("name",),
    "nid_number": ("nid", "id no", "id number", "national id", "id"),
    "dob": ("date of birth", "dob", "birth"),
    "address": ("address", "addr"),
}


@dataclass(frozen=True, slots=True)
class ExtractedField:
    """A single extracted value plus the provider's optional confidence.

    ``confidence`` is a 0.0–1.0 score when the provider reports one, else
    ``None``. ``value`` is the normalized string (``dob`` is normalized to an
    ISO ``YYYY-MM-DD`` string so it survives JSON transport to Django).
    """

    value: str | None = None
    confidence: float | None = None


@dataclass(frozen=True, slots=True)
class ExtractedTenant:
    """Normalized OCR result — the JSON shape returned to the caller.

    Every field is always present as an :class:`ExtractedField` (absent ->
    ``value=None``) so Django never key-checks. ``nid_number`` is the *plaintext*
    document number; it is returned for one-time review/encryption and must never
    be logged or persisted raw.
    """

    name: ExtractedField = field(default_factory=ExtractedField)
    nid_number: ExtractedField = field(default_factory=ExtractedField)
    dob: ExtractedField = field(default_factory=ExtractedField)
    address: ExtractedField = field(default_factory=ExtractedField)

    def to_dict(self) -> dict[str, Any]:
        """Serialize to the JSON envelope the gateway hands back."""
        return {name: asdict(getattr(self, name)) for name in _FIELDS}

    def is_empty(self) -> bool:
        """True when no field carried a value (e.g. an unreadable image)."""
        return all(getattr(self, name).value is None for name in _FIELDS)


def _normalize_dob(text: str) -> str | None:
    """Coerce a free-text date into an ISO ``YYYY-MM-DD`` string, or ``None``."""
    iso = _ISO_DATE.search(text)
    if iso:
        return f"{iso.group(1)}-{iso.group(2)}-{iso.group(3)}"
    dmy = _DMY_DATE.search(text)
    if dmy:
        return f"{dmy.group(3)}-{dmy.group(2)}-{dmy.group(1)}"
    return None


def _normalize_nid(text: str) -> str | None:
    """Strip everything but digits from a candidate NID string."""
    digits = re.sub(r"\D", "", text)
    return digits or None


def _clean_text(text: str) -> str | None:
    value = text.strip()
    return value or None


class GoogleVisionOcrProvider(HTTPProvider):
    """OCR client: NID image bytes → normalized :class:`ExtractedTenant`.

    Speaks the Google Cloud Vision ``DOCUMENT_TEXT_DETECTION`` REST contract by
    default. The endpoint and API key both come from :class:`ProviderConfig`;
    swap ``endpoint_url`` to target a compatible self-hosted OCR backend.
    """

    category = "ocr"

    def __init__(self, config: ProviderConfig, client: httpx.AsyncClient) -> None:
        if not config.endpoint_url:
            config = ProviderConfig(
                provider_key=config.provider_key,
                category=config.category or self.category,
                model_name=config.model_name,
                endpoint_url=GOOGLE_VISION_ENDPOINT,
                api_key=config.api_key,
                params=config.params,
                is_primary=config.is_primary,
                is_fallback=config.is_fallback,
                active=config.active,
            )
        super().__init__(config, client)

    async def call(self, payload: dict[str, Any]) -> ProviderResult:
        """OCR ``payload['image']`` (raw bytes or base64) → normalized fields.

        Returns a :class:`ProviderResult` whose ``data`` is the
        :class:`ExtractedTenant` JSON envelope.
        """
        image_b64 = _encode_image(self.config.provider_key, payload.get("image"))
        request = {
            "requests": [
                {
                    "image": {"content": image_b64},
                    "features": [{"type": "DOCUMENT_TEXT_DETECTION"}],
                }
            ]
        }
        # API key is passed as a query param (Vision REST), never in the body/logs.
        params = {"key": self.config.api_key} if self.config.api_key else None
        try:
            resp = await self._client.post(
                self.config.endpoint_url,
                json=request,
                params=params,
            )
            resp.raise_for_status()
        except httpx.HTTPStatusError as exc:
            raise ProviderError(
                self.config.provider_key, f"HTTP {exc.response.status_code}"
            ) from exc
        except httpx.HTTPError as exc:
            raise ProviderError(self.config.provider_key, str(exc)) from exc

        try:
            body = resp.json()
        except ValueError as exc:
            raise ProviderError(self.config.provider_key, f"bad response: {exc}") from exc

        extracted = self._parse_vision(body)
        return ProviderResult(data=extracted.to_dict())

    def _parse_vision(self, body: dict[str, Any]) -> ExtractedTenant:
        """Map a Vision ``images:annotate`` response to :class:`ExtractedTenant`.

        Reads the first response's ``fullTextAnnotation.text`` (or the legacy
        ``textAnnotations[0].description``) and pulls labelled values off each
        line. Unknown shapes degrade gracefully to an empty result rather than
        raising — an unreadable image is a valid (empty) outcome, not an error.
        """
        responses = body.get("responses")
        if not isinstance(responses, list) or not responses:
            return ExtractedTenant()
        first = responses[0]
        if not isinstance(first, dict):
            return ExtractedTenant()
        if isinstance(first.get("error"), dict):
            message = first["error"].get("message", "vision error")
            raise ProviderError(self.config.provider_key, str(message))

        text = ""
        full = first.get("fullTextAnnotation")
        if isinstance(full, dict) and isinstance(full.get("text"), str):
            text = full["text"]
        else:
            anns = first.get("textAnnotations")
            if isinstance(anns, list) and anns and isinstance(anns[0], dict):
                text = str(anns[0].get("description", ""))
        return _extract_fields(text)


def build_ocr_provider(
    config: ProviderConfig, client: httpx.AsyncClient
) -> GoogleVisionOcrProvider:
    """Factory helper mirroring the router's :data:`ProviderFactory` shape."""
    return GoogleVisionOcrProvider(config, client)


def _encode_image(provider_key: str, image: Any) -> str:
    """Return base64-encoded image content for the Vision request body."""
    if isinstance(image, bytes):
        return base64.b64encode(image).decode("ascii")
    if isinstance(image, str) and image:
        # Already-base64 content (e.g. forwarded from Django).
        return image
    raise ProviderError(provider_key, "missing image bytes in payload")


def _extract_fields(text: str) -> ExtractedTenant:
    """Pull labelled fields off OCR text lines into an :class:`ExtractedTenant`."""
    values: dict[str, str | None] = dict.fromkeys(_FIELDS, None)
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        lower = line.lower()
        for field_name, labels in _LABELS.items():
            if values[field_name] is not None:
                continue
            for label in labels:
                idx = lower.find(label)
                if idx == -1:
                    continue
                tail = line[idx + len(label):].lstrip(" :\t-")
                if tail:
                    values[field_name] = tail
                break

    dob_value = _normalize_dob(values["dob"]) if values["dob"] else None
    if dob_value is None:
        dob_value = _normalize_dob(text)
    nid_value = _normalize_nid(values["nid_number"]) if values["nid_number"] else None
    return ExtractedTenant(
        name=ExtractedField(_clean_text(values["name"]) if values["name"] else None),
        nid_number=ExtractedField(nid_value),
        dob=ExtractedField(dob_value),
        address=ExtractedField(_clean_text(values["address"]) if values["address"] else None),
    )
