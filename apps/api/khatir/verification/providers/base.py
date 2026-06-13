"""Swappable EC verification provider contract — EPIC-17.T-002.

A :class:`VerificationProvider` submits an NID + name + DOB to an Election
Commission verification vendor and returns a normalized, boolean-only
:class:`~khatir.verification.providers.dto.VerificationOutcome`. It never
returns or stores the raw EC payload — only matched / not_matched / error plus
an opaque vendor ``provider_ref``.

This mirrors the EPIC-14 AI-provider abstraction (``services/ai-gateway``):
a thin per-vendor client behind a stable interface, so the concrete vendor can
be swapped (or routed through the AI gateway) without touching callers.
"""

from __future__ import annotations

import abc

from .dto import VerificationOutcome

__all__ = ["VerificationProvider", "VerificationProviderError"]


class VerificationProviderError(RuntimeError):
    """Raised for unrecoverable provider misconfiguration.

    Distinct from a vendor/transport *failure*, which a provider must catch and
    normalize into an ``error`` :class:`VerificationOutcome` (so callers always
    get a boolean-style result). This exception is reserved for programmer/setup
    errors such as a missing DPA reference, where the call must not proceed.
    """


class VerificationProvider(abc.ABC):
    """The single behaviour every EC verification vendor client implements."""

    @abc.abstractmethod
    def verify(self, nid: str, name: str, dob: str) -> VerificationOutcome:
        """Submit ``nid`` + ``name`` + ``dob`` to the vendor; return a boolean outcome.

        Implementations MUST:

        * normalize the vendor response to ``matched`` / ``not_matched`` /
          ``error`` and discard the raw EC payload before returning;
        * never return or persist raw EC fields — only the outcome + opaque
          ``provider_ref``;
        * catch transport/vendor failures and return an ``error`` outcome rather
          than propagating arbitrary exceptions.

        Args:
            nid: National ID number to verify.
            name: Claimed full name of the subject.
            dob: Claimed date of birth (ISO ``YYYY-MM-DD``).

        Returns:
            A normalized, boolean-only :class:`VerificationOutcome`.
        """
        raise NotImplementedError
