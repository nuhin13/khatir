"""Normalized verification DTOs — EPIC-17.T-002.

The provider layer returns a :class:`VerificationOutcome`: a deliberately
**boolean-only** result. The only fields that ever leave the provider are the
match outcome (matched / not_matched / error) and an *opaque* vendor
``provider_ref`` transaction id kept for audit/dispute. The raw EC payload
(name, DOB, address, photo, NID number, …) is extracted into the boolean and
then discarded — it is never carried on this DTO and must never be persisted.
"""

from __future__ import annotations

from dataclasses import dataclass

from khatir.verification.enums import VerificationResult

__all__ = ["VerificationOutcome"]


@dataclass(frozen=True, slots=True)
class VerificationOutcome:
    """Normalized, boolean-only result of one EC verification attempt.

    Attributes:
        result: ``matched`` / ``not_matched`` / ``error`` — the *only* outcome
            signal. There is no raw-data field by design.
        provider_ref: Opaque vendor transaction id for audit/dispute. NOT the
            EC data itself; may be empty when the vendor returns no reference
            (e.g. a transport error before any transaction was created).
        error_detail: Human-readable failure reason, populated only when
            ``result`` is ``error``. Never contains EC PII — it describes the
            transport/vendor failure, not the subject's data.
    """

    result: VerificationResult
    provider_ref: str = ""
    error_detail: str = ""

    @property
    def matched(self) -> bool:
        """True only for a definitive positive match."""
        return self.result == VerificationResult.MATCHED

    @property
    def is_error(self) -> bool:
        """True when the attempt failed (vs. a definitive not-matched)."""
        return self.result == VerificationResult.ERROR

    @classmethod
    def matched_result(cls, provider_ref: str = "") -> VerificationOutcome:
        return cls(result=VerificationResult.MATCHED, provider_ref=provider_ref)

    @classmethod
    def not_matched_result(cls, provider_ref: str = "") -> VerificationOutcome:
        return cls(result=VerificationResult.NOT_MATCHED, provider_ref=provider_ref)

    @classmethod
    def error_result(
        cls, error_detail: str, provider_ref: str = ""
    ) -> VerificationOutcome:
        return cls(
            result=VerificationResult.ERROR,
            provider_ref=provider_ref,
            error_detail=error_detail,
        )
