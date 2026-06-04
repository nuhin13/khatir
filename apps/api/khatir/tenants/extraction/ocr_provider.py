"""OCR provider impl + registry (T-004 §3/§5).

``DefaultOcrProvider`` calls the configured OCR backend (creds from env/config)
and normalizes its response into an :class:`ExtractedTenant`. The wire call is
isolated in :meth:`DefaultOcrProvider._raw_extract` so tests mock exactly one
seam and the public ``extract_from_image`` contract (normalization) is exercised
end-to-end. EPIC-14 will register an AI-gateway-backed provider here without
changing callers.

The raw provider payload never leaves this module — only the normalized DTO is
returned (privacy, self-review §14).
"""

from __future__ import annotations

from datetime import date
from typing import Any

from khatir.core.config import get_config

from .base import TenantExtractionProvider
from .dto import ExtractedField, ExtractedTenant
from .normalize import normalize_date, normalize_nid, normalize_text

#: ``SystemConfig`` key selecting the OCR provider; defaults to the built-in one.
OCR_PROVIDER_CONFIG_KEY = "ocr_provider_key"
DEFAULT_OCR_PROVIDER_KEY = "default"


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


#: provider-key -> factory. EPIC-14 appends its gateway-backed provider here.
_OCR_PROVIDERS: dict[str, type[TenantExtractionProvider]] = {
    DEFAULT_OCR_PROVIDER_KEY: DefaultOcrProvider,
}


def get_ocr_provider() -> TenantExtractionProvider:
    """Return the OCR provider named by the ``ocr_provider_key`` config.

    Falls back to the built-in ``default`` provider when the key is unset or
    names an unknown provider, so callers always get a working instance.
    """
    key = get_config(OCR_PROVIDER_CONFIG_KEY, DEFAULT_OCR_PROVIDER_KEY)
    provider_cls = _OCR_PROVIDERS.get(key, DefaultOcrProvider)
    return provider_cls()
