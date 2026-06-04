"""Normalized extraction DTOs (T-004 §2).

:class:`ExtractedTenant` is the single shape every OCR/ASR provider returns — a
small, provider-agnostic value object the service/endpoint layer (T-005/T-006)
consumes without knowing which provider produced it. Each field carries an
optional per-field ``confidence`` (``ExtractedField``) so the review UI can flag
low-confidence values. These DTOs are deliberately free of the raw provider
payload: only normalized values cross this boundary (privacy, self-review §14).
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date


@dataclass(frozen=True, slots=True)
class ExtractedField:
    """A single extracted value plus the provider's optional confidence.

    ``confidence`` is a 0.0–1.0 score when the provider reports one, else
    ``None``. ``value`` is already normalized to the field's Python type
    (``str`` for text fields, ``date`` for ``dob``).
    """

    value: str | date | None
    confidence: float | None = None


@dataclass(frozen=True, slots=True)
class ExtractedTenant:
    """The normalized result of an OCR/ASR extraction.

    Every field is an :class:`ExtractedField`; absent fields are still present
    as an ``ExtractedField(value=None)`` so callers never key-check. ``nid_number``
    is the *plaintext* number extracted from the document — it is returned to the
    caller for one-time review/encryption and must never be logged or persisted
    raw (the model encrypts it via ``Tenant.set_nid``).
    """

    name: ExtractedField = field(default_factory=lambda: ExtractedField(None))
    nid_number: ExtractedField = field(default_factory=lambda: ExtractedField(None))
    dob: ExtractedField = field(default_factory=lambda: ExtractedField(None))
    address: ExtractedField = field(default_factory=lambda: ExtractedField(None))

    def is_empty(self) -> bool:
        """True when no field carried a value (e.g. an unreadable image)."""
        return all(
            getattr(self, name).value is None
            for name in ("name", "nid_number", "dob", "address")
        )
