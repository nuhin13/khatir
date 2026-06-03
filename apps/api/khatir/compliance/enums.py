"""Compliance-domain enums — PDPA / Domain 9 of ``06_database_schema.md``.

Domain-specific (used only by ``ConsentRecord`` and ``DataRequest``), so they
live in the owning app rather than ``khatir.core.enums``. Wire values are the
single source of truth in ``docs/architecture/enums.md`` — lowercase
snake_case strings, never integers.
"""

from django.db import models


class ConsentType(models.TextChoices):
    """The consent category being recorded."""

    PDPA_DATA_COLLECTION = "pdpa_data_collection", "PDPA data collection"
    PDPA_NID_VERIFICATION = "pdpa_nid_verification", "PDPA NID verification"
    PDPA_DATA_SHARING = "pdpa_data_sharing", "PDPA data sharing"
    MARKETING = "marketing", "Marketing"


class DataRequestType(models.TextChoices):
    """What type of PDPA data request the subject is making."""

    EXPORT = "export", "Export"
    DELETE = "delete", "Delete"


class DataRequestStatus(models.TextChoices):
    """Processing status of a DataRequest."""

    PENDING = "pending", "Pending"
    PROCESSING = "processing", "Processing"
    COMPLETED = "completed", "Completed"
    REJECTED = "rejected", "Rejected"
