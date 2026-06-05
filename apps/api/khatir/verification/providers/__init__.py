"""EC verification provider abstraction — EPIC-17.T-002."""

from .base import VerificationProvider, VerificationProviderError
from .dto import VerificationOutcome
from .ec_provider import ECVerificationProvider

__all__ = [
    "VerificationProvider",
    "VerificationProviderError",
    "VerificationOutcome",
    "ECVerificationProvider",
]
