"""AI provider clients for the gateway.

Each provider is a thin HTTP client wrapping a single vendor API behind the
common :class:`~providers.base.Provider` protocol so the router can treat them
interchangeably.
"""

from __future__ import annotations

from providers.asr import ASRProvider, build_asr_provider
from providers.base import (
    HTTPProvider,
    Provider,
    ProviderConfig,
    ProviderError,
    ProviderResult,
)
from providers.chat import ChatProvider, build_chat_provider
from providers.ocr import (
    GOOGLE_VISION_ENDPOINT,
    ExtractedField,
    ExtractedTenant,
    GoogleVisionOcrProvider,
    build_ocr_provider,
)

__all__ = [
    "GOOGLE_VISION_ENDPOINT",
    "ASRProvider",
    "ChatProvider",
    "ExtractedField",
    "ExtractedTenant",
    "GoogleVisionOcrProvider",
    "HTTPProvider",
    "Provider",
    "ProviderConfig",
    "ProviderError",
    "ProviderResult",
    "build_asr_provider",
    "build_chat_provider",
    "build_ocr_provider",
]
