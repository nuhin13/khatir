"""Government-export domain models — EPIC-26 / ``06_database_schema.md``.

``GovExport`` persists one row each time a landlord generates a bulk
government-submission export package (e.g. a tenant registration batch for a
government authority). It records which landlord the export belongs to, the
period it covers, the format/template version used (so format updates can be
tracked and re-runs distinguished), a pointer to the generated package in
encrypted object storage, how many records the package contains, and the
generation/submission lifecycle status.

Design notes:
- ``landlord`` is the owning user (``AUTH_USER_MODEL`` — the platform uses one
  user table for every human role; the landlord is identified by their owning
  relationship, mirroring ``properties.Building.owner``). PROTECT — an export
  ledger row must outlive nothing of the landlord's, but the landlord cannot be
  hard-deleted while export rows reference them.
- ``file_ref`` is a storage key into encrypted object storage (EPIC-04 T-003).
  No raw PII payload is stored on this ledger row.
- This is a ledger/generated row, not a user-facing soft-deletable entity, so
  it inherits ``TimeStampedModel`` rather than ``SoftDeleteModel``.
- Feature is flag-gated (default OFF) at the endpoint layer (EPIC-26 T-005);
  the model itself carries no flag.
"""

from __future__ import annotations

from django.conf import settings
from django.db import models

from khatir.core.models import TimeStampedModel

from .enums import GovExportStatus


class GovExport(TimeStampedModel):
    """A record of a generated government-submission export package.

    One row is created each time a landlord generates an export package. It
    captures the landlord, the covered period, the format version used, a
    reference to the stored package, the record count, and the generated /
    submitted lifecycle status.
    """

    landlord = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="gov_exports",
        help_text=(
            "The landlord who owns this export. "
            "PROTECT — cannot delete a landlord while gov-export records exist."
        ),
    )
    period = models.CharField(
        max_length=7,
        help_text="The period the export covers, e.g. '2026-05' (YYYY-MM).",
    )
    format_version = models.CharField(
        max_length=40,
        help_text=(
            "The export format/template version used (e.g. '2024-v1'). "
            "Allows distinguishing records across format updates."
        ),
    )
    file_ref = models.CharField(
        max_length=255,
        help_text=(
            "Storage key for the generated export package in encrypted object "
            "storage (EPIC-04 T-003). Never stores raw PII payload."
        ),
    )
    record_count = models.PositiveIntegerField(
        default=0,
        help_text="Number of records contained in the export package.",
    )
    status = models.CharField(
        max_length=20,
        choices=GovExportStatus.choices,
        default=GovExportStatus.GENERATED,
        help_text="Lifecycle status: 'generated' or 'submitted'.",
    )

    class Meta:
        ordering = ("-created_at",)
        indexes = [
            models.Index(fields=["landlord"]),
            models.Index(fields=["period"]),
            models.Index(fields=["status"]),
            models.Index(fields=["created_at"]),
        ]

    def __str__(self) -> str:
        return (
            f"GovExport #{self.pk} · landlord {self.landlord_id} "
            f"· {self.period} · {self.format_version} · {self.status}"
        )
