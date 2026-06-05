"""Lease-documents domain enums (EPIC-18).

Domain-specific (used only by ``LeaseDocument``), so they live in the owning app
rather than ``khatir.core.enums``. Wire values are lowercase snake_case strings,
never integers — consistent with ``docs/architecture/enums.md``.
"""

from django.db import models


class LeaseDocumentStatus(models.TextChoices):
    """Lifecycle status of an AI-generated tenancy agreement document."""

    DRAFT = "draft", "Draft"
    FINAL = "final", "Final"
