"""AI provider clients for the gateway.

Each provider is a thin HTTP client wrapping a single vendor API behind the
common :class:`~providers.base.Provider` protocol so the router can treat them
interchangeably.
"""

from __future__ import annotations

from providers.base import Provider, ProviderConfig, ProviderError, ProviderResult

__all__ = [
    "Provider",
    "ProviderConfig",
    "ProviderError",
    "ProviderResult",
]
