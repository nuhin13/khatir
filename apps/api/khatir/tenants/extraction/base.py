"""Extraction provider interface (T-004 §3).

:class:`TenantExtractionProvider` is the ABC every concrete OCR/ASR provider
implements. Endpoints/services depend only on this interface and obtain an
instance via :func:`khatir.tenants.extraction.get_ocr_provider` /
``get_asr_provider`` (config-driven), so a provider can be swapped — including
EPIC-14's AI-gateway-backed impl — without touching call sites.

Both methods take raw bytes and return a normalized :class:`ExtractedTenant`.
Implementations must return only the normalized result and never persist or log
the raw provider payload (privacy, self-review §14).
"""

from __future__ import annotations

from abc import ABC, abstractmethod

from .dto import ExtractedTenant


class TenantExtractionProvider(ABC):
    """Extract tenant fields from an NID image (OCR) or Bangla audio (ASR)."""

    #: Stable provider key (matches the ``*_provider_key`` config value).
    key: str

    @abstractmethod
    def extract_from_image(self, image: bytes) -> ExtractedTenant:
        """Run OCR on an NID ``image`` and return normalized tenant fields.

        Implementations that only support one modality may raise
        :class:`NotImplementedError`; the registry pairs OCR/ASR keys so this is
        not normally hit.
        """
        raise NotImplementedError

    @abstractmethod
    def extract_from_audio(self, audio: bytes) -> ExtractedTenant:
        """Run ASR on Bangla ``audio`` and return normalized tenant fields."""
        raise NotImplementedError
