"""Verification-domain enums — EPIC-17 (NID/EC verification).

Wire values are the single source of truth — lowercase snake_case strings,
never integers. A verification attempt records **only** a boolean-style
outcome: matched / not_matched / error. Raw EC payloads are never persisted.
"""

from django.db import models


class VerificationResult(models.TextChoices):
    """Outcome of a single EC verification attempt (boolean-only)."""

    MATCHED = "matched", "Matched"
    NOT_MATCHED = "not_matched", "Not matched"
    ERROR = "error", "Error"
