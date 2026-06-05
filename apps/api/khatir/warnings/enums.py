"""Warnings-domain enums (EPIC-20).

Domain-specific (used only by ``Warning``), so they live in the owning app
rather than ``khatir.core.enums``. Wire values are lowercase snake_case
strings, never integers.
"""

from django.db import models


class WarningType(models.TextChoices):
    """Reason category of a private landlord-to-tenant warning."""

    LATE_RENT = "late_rent", "Late rent"
    LEASE_VIOLATION = "lease_violation", "Lease violation"
    NOISE = "noise", "Noise"
    OTHER = "other", "Other"
