"""Tenants-domain enums — Domain 3 of ``06_database_schema.md``.

Domain-specific (used only by ``Tenant``), so it lives in the owning app rather
than ``khatir.core.enums``. Wire values are the single source of truth in
``docs/architecture/enums.md`` — lowercase snake_case strings, never integers.
"""

from django.db import models


class VerificationStatus(models.TextChoices):
    """EC/NID verification outcome for a tenant (verification itself is P1)."""

    UNVERIFIED = "unverified", "Unverified"
    MATCHED = "matched", "Matched"
    NOT_MATCHED = "not_matched", "Not matched"
    ERROR = "error", "Error"
