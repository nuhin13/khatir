"""ASR provider impl + registry (T-004 §3/§5).

``DefaultAsrProvider`` transcribes Bangla audio of a tenant reading their NID
details and normalizes the parsed fields into an :class:`ExtractedTenant`,
mirroring the OCR provider's shape so the service layer treats both modalities
uniformly. The backend call is isolated in :meth:`DefaultAsrProvider._raw_extract`
(the only test seam); the raw transcript/payload never leaves this module
(privacy, self-review §14). EPIC-14 registers a gateway-backed provider here.
"""

from __future__ import annotations

from datetime import date
from typing import Any

from khatir.core.config import get_config

from .base import TenantExtractionProvider
from .dto import ExtractedField, ExtractedTenant
from .normalize import normalize_date, normalize_nid, normalize_text

#: ``SystemConfig`` key selecting the ASR provider; defaults to the built-in one.
ASR_PROVIDER_CONFIG_KEY = "asr_provider_key"
DEFAULT_ASR_PROVIDER_KEY = "default"


class DefaultAsrProvider(TenantExtractionProvider):
    """Built-in ASR provider: Bangla audio bytes → normalized tenant fields."""

    key = DEFAULT_ASR_PROVIDER_KEY

    def _raw_extract(self, audio: bytes) -> dict[str, Any]:
        """Call the underlying ASR backend and return its parsed response.

        The single network/SDK seam — mocked in tests. A real impl reads creds
        from env/config, transcribes ``audio`` (bn), and parses fields out of the
        transcript; replaced by EPIC-14's gateway impl per deployment.
        """
        raise NotImplementedError(
            "Wire a concrete ASR backend or mock _raw_extract in tests."
        )

    def extract_from_audio(self, audio: bytes) -> ExtractedTenant:
        """Transcribe ``audio`` and normalize the result into ``ExtractedTenant``."""
        return _normalize_payload(self._raw_extract(audio))

    def extract_from_image(self, image: bytes) -> ExtractedTenant:  # noqa: ARG002
        raise NotImplementedError("ASR provider does not handle images; use OCR.")


def _confidence(scores: Any, field: str) -> float | None:
    if isinstance(scores, dict):
        value = scores.get(field)
        if isinstance(value, (int, float)):
            return float(value)
    return None


def _normalize_payload(raw: dict[str, Any]) -> ExtractedTenant:
    """Map an ASR backend's parsed fields to the normalized DTO."""
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
_ASR_PROVIDERS: dict[str, type[TenantExtractionProvider]] = {
    DEFAULT_ASR_PROVIDER_KEY: DefaultAsrProvider,
}


def get_asr_provider() -> TenantExtractionProvider:
    """Return the ASR provider named by the ``asr_provider_key`` config.

    Falls back to the built-in ``default`` provider when the key is unset or
    names an unknown provider, so callers always get a working instance.
    """
    key = get_config(ASR_PROVIDER_CONFIG_KEY, DEFAULT_ASR_PROVIDER_KEY)
    provider_cls = _ASR_PROVIDERS.get(key, DefaultAsrProvider)
    return provider_cls()
