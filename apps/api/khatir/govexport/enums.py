"""Gov-export-domain enums — EPIC-26 / ``06_database_schema.md``.

Domain-specific (used only by ``GovExport``), so they live in the owning app
rather than ``khatir.core.enums``. Wire values are lowercase snake_case
strings, never integers.
"""

from django.db import models


class GovExportStatus(models.TextChoices):
    """Lifecycle status of a generated government export package."""

    GENERATED = "generated", "Generated"
    SUBMITTED = "submitted", "Submitted"
