"""OCR provider impl + registry (T-004 §3/§5, retrofit EPIC-14.T-008).

``DefaultOcrProvider`` calls the configured OCR backend (creds from env/config)
and normalizes its response into an :class:`ExtractedTenant`. The wire call is
isolated in :meth:`DefaultOcrProvider._raw_extract` so tests mock exactly one
seam and the public ``extract_from_image`` contract (normalization) is exercised
end-to-end.

``GatewayOcrProvider`` (EPIC-14.T-008) is the AI-gateway-backed impl: it forwards
the image to the FastAPI ``ai-gateway`` via ``aiproxy_client.extract_nid`` and
maps the gateway's already-normalized envelope into the same
:class:`ExtractedTenant`. Provider selection stays config-driven so callers and
the endpoint contract are unchanged — only the provider impl differs.

The raw provider payload never leaves this module — only the normalized DTO is
returned (privacy, self-review §14).
"""

from __future__ import annotations

from datetime import date
from typing import Any

from khatir.ai_providers import client as aiproxy_client
from khatir.core.config import get_config

from .base import TenantExtractionProvider
from .dto import ExtractedField, ExtractedTenant
from .normalize import normalize_date, normalize_nid, normalize_text

#: ``SystemConfig`` key selecting the OCR provider; defaults to the built-in one.
OCR_PROVIDER_CONFIG_KEY = "ocr_provider_key"
DEFAULT_OCR_PROVIDER_KEY = "default"
#: Provider key routing OCR through the AI gateway (EPIC-14.T-008).
GATEWAY_OCR_PROVIDER_KEY = "gateway"


class DefaultOcrProvider(TenantExtractionProvider):
    """Built-in OCR provider: NID image bytes → normalized tenant fields."""

    key = DEFAULT_OCR_PROVIDER_KEY

    def _raw_extract(self, image: bytes) -> dict[str, Any]:
        """Call the underlying OCR backend and return its raw response.

        The single network/SDK seam — mocked in tests. A real impl reads creds
        from env/config and posts ``image``; here it is left for the concrete
        backend wired per deployment (and replaced by EPIC-14's gateway impl).
        """
        raise NotImplementedError(
            "Wire a concrete OCR backend or mock _raw_extract in tests."
        )

    def extract_from_image(self, image: bytes) -> ExtractedTenant:
        """OCR ``image`` and normalize the result into an ``ExtractedTenant``."""
        return _normalize_payload(self._raw_extract(image))

    def extract_from_audio(self, audio: bytes) -> ExtractedTenant:  # noqa: ARG002
        raise NotImplementedError("OCR provider does not handle audio; use ASR.")


class GatewayOcrProvider(TenantExtractionProvider):
    """OCR provider that routes through the AI gateway (EPIC-14.T-008).

    Forwards the NID image to the ``ai-gateway`` microservice via
    :func:`khatir.ai_providers.client.extract_nid` (which presents the shared
    internal token and selects the vendor). The gateway returns the *already
    normalized* per-field envelope (``{field: {value, confidence}}`` with ``dob``
    as an ISO ``YYYY-MM-DD`` string); this provider maps it onto the local
    :class:`ExtractedTenant` so the endpoint contract (T-005) is unchanged.

    Only the normalized DTO crosses this boundary — the raw gateway/vendor
    payload is parsed and discarded here (privacy, self-review §14).
    """

    key = GATEWAY_OCR_PROVIDER_KEY

    def extract_from_image(self, image: bytes) -> ExtractedTenant:
        """OCR ``image`` via the gateway and normalize into ``ExtractedTenant``."""
        result = aiproxy_client.extract_nid(image)
        return _normalize_gateway_payload(result.data)

    def extract_from_audio(self, audio: bytes) -> ExtractedTenant:  # noqa: ARG002
        raise NotImplementedError("OCR provider does not handle audio; use ASR.")


def _confidence(scores: Any, field: str) -> float | None:
    """Pull a per-field confidence from the provider payload, if present."""
    if isinstance(scores, dict):
        value = scores.get(field)
        if isinstance(value, (int, float)):
            return float(value)
    return None


def _normalize_payload(raw: dict[str, Any]) -> ExtractedTenant:
    """Map an OCR backend's raw fields to the normalized DTO.

    Accepts the loose shape providers emit (extra keys ignored, missing keys ->
    ``None``) and coerces ``dob`` to a :class:`datetime.date`. Confidences come
    from an optional ``confidence`` map keyed by our field names.
    """
    scores = raw.get("confidence")
    dob: date | None = normalize_date(raw.get("dob"))
    return ExtractedTenant(
        name=ExtractedField(normalize_text(raw.get("name")), _confidence(scores, "name")),
        nid_number=ExtractedField(
            normalize_nid(raw.get("nid_number")), _confidence(scores, "nid_number")
        ),
        dob=ExtractedField(dob, _confidence(scores, "dob")),
        address=ExtractedField(
            normalize_text(raw.get("address")), _confidence(scores, "address")
        ),
    )


def _gateway_field(envelope: Any, name: str) -> tuple[Any, float | None]:
    """Pull ``(value, confidence)`` for ``name`` from a gateway field envelope.

    The gateway returns each field as ``{"value": ..., "confidence": ...}``;
    tolerate a missing/odd shape by degrading to ``(None, None)``.
    """
    field_obj = envelope.get(name) if isinstance(envelope, dict) else None
    if not isinstance(field_obj, dict):
        return None, None
    confidence = field_obj.get("confidence")
    confidence = float(confidence) if isinstance(confidence, (int, float)) else None
    return field_obj.get("value"), confidence


def _normalize_gateway_payload(data: dict[str, Any]) -> ExtractedTenant:
    """Map the gateway's per-field envelope to the normalized DTO.

    The gateway already normalizes values (``dob`` as an ISO ``YYYY-MM-DD``
    string); the local normalizers are re-applied so the DTO's type promises
    hold regardless of which side did the work, and per-field confidences flow
    straight through.
    """
    name_v, name_c = _gateway_field(data, "name")
    nid_v, nid_c = _gateway_field(data, "nid_number")
    dob_v, dob_c = _gateway_field(data, "dob")
    addr_v, addr_c = _gateway_field(data, "address")
    return ExtractedTenant(
        name=ExtractedField(normalize_text(name_v), name_c),
        nid_number=ExtractedField(normalize_nid(nid_v), nid_c),
        dob=ExtractedField(normalize_date(dob_v), dob_c),
        address=ExtractedField(normalize_text(addr_v), addr_c),
    )


#: provider-key -> factory. The gateway-backed provider (EPIC-14.T-008) routes
#: OCR through the ``ai-gateway`` microservice; ``default`` is the local seam.
_OCR_PROVIDERS: dict[str, type[TenantExtractionProvider]] = {
    DEFAULT_OCR_PROVIDER_KEY: DefaultOcrProvider,
    GATEWAY_OCR_PROVIDER_KEY: GatewayOcrProvider,
}


def get_ocr_provider() -> TenantExtractionProvider:
    """Return the OCR provider named by the ``ocr_provider_key`` config.

    Falls back to the built-in ``default`` provider when the key is unset or
    names an unknown provider, so callers always get a working instance.
    """
    key = get_config(OCR_PROVIDER_CONFIG_KEY, DEFAULT_OCR_PROVIDER_KEY)
    provider_cls = _OCR_PROVIDERS.get(key, DefaultOcrProvider)
    return provider_cls()
