"""Gatekeeper-domain enums — visitor-entry / caretaker feature.

Domain-specific (used only by ``CaretakerAssignment`` and ``VisitorEntry``), so
they live in the owning app rather than ``khatir.core.enums``. Wire values are
the single source of truth in ``docs/architecture/enums.md`` — lowercase
snake_case strings, never integers on the wire.
"""

from django.db import models


class CaretakerAssignmentStatus(models.TextChoices):
    """Lifecycle of a caretaker's assignment to a building."""

    ACTIVE = "active", "Active"
    REVOKED = "revoked", "Revoked"


class VisitorEntryStatus(models.TextChoices):
    """Approval state of a logged visitor entry."""

    PENDING = "pending", "Pending"
    APPROVED = "approved", "Approved"
    DENIED = "denied", "Denied"
