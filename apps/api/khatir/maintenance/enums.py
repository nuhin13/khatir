"""Maintenance-domain enums — Domain 6 of ``06_database_schema.md``.

Domain-specific (used only by ``MaintenanceRequest`` and ``Expense``), so they
live in the owning app rather than ``khatir.core.enums``. Wire values are the
single source of truth in ``docs/architecture/enums.md`` — lowercase snake_case
strings, never integers.
"""

from django.db import models


class MaintenanceCategory(models.TextChoices):
    """Category of a maintenance request or expense."""

    PLUMBING = "plumbing", "Plumbing"
    ELECTRICAL = "electrical", "Electrical"
    PAINT = "paint", "Paint"
    STRUCTURAL = "structural", "Structural"
    APPLIANCE = "appliance", "Appliance"
    UTILITY = "utility", "Utility"
    OTHER = "other", "Other"


class MaintenanceStatus(models.TextChoices):
    """Lifecycle status of a maintenance request."""

    OPEN = "open", "Open"
    RESOLVED = "resolved", "Resolved"


class ExpenseCategory(models.TextChoices):
    """Category of an expense on a unit."""

    PLUMBING = "plumbing", "Plumbing"
    PAINT = "paint", "Paint"
    ELECTRICAL = "electrical", "Electrical"
    STRUCTURAL = "structural", "Structural"
    APPLIANCE = "appliance", "Appliance"
    UTILITY = "utility", "Utility"
    OTHER = "other", "Other"


class ExpenseSource(models.TextChoices):
    """How the expense originated."""

    REQUEST = "request", "Request"
    MANUAL = "manual", "Manual"
