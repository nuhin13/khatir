"""Leases-domain enums — Domain 4 of ``06_database_schema.md``.

Domain-specific (used only by ``Lease`` and ``RentSchedule``), so they live in
the owning app rather than ``khatir.core.enums``. Wire values are the single
source of truth in ``docs/architecture/enums.md`` — lowercase snake_case
strings, never integers.
"""

from django.db import models


class LeaseStatus(models.TextChoices):
    """Lifecycle status of a rental agreement."""

    DRAFT = "draft", "Draft"
    ACTIVE = "active", "Active"
    ENDED = "ended", "Ended"
    TERMINATED = "terminated", "Terminated"


class RentScheduleStatus(models.TextChoices):
    """Payment status of a single monthly rent schedule row."""

    PENDING = "pending", "Pending"
    REQUESTED = "requested", "Requested"
    PAID = "paid", "Paid"
    OVERDUE = "overdue", "Overdue"
