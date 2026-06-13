"""Tenant field-extraction providers (OCR/ASR) — EPIC-04.T-004.

A thin, swappable abstraction over the OCR (NID image) and ASR (Bangla audio)
providers used to pre-fill tenant fields. Concrete impls are selected via the
``ocr_provider_key`` / ``asr_provider_key`` ``SystemConfig`` keys, so the
provider can be replaced — and later routed through the AI gateway (EPIC-14) —
without touching endpoints or screens. Only the normalized :class:`ExtractedTenant`
is returned; the raw provider payload is never persisted (privacy).
"""

from __future__ import annotations

from .asr_provider import get_asr_provider
from .base import TenantExtractionProvider
from .dto import ExtractedField, ExtractedTenant
from .ocr_provider import get_ocr_provider

__all__ = [
    "ExtractedField",
    "ExtractedTenant",
    "TenantExtractionProvider",
    "get_asr_provider",
    "get_ocr_provider",
]
