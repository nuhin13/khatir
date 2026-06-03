"""Notifications-domain enums — Domain 8 of ``06_database_schema.md``.

Domain-specific enums used only by the notifications models live here.
Cross-app enums (e.g. ``Channel``) are imported from ``khatir.core.enums``.
Wire values are lowercase snake_case strings — never integers on the wire.
"""

from django.db import models


class NotificationAudienceType(models.TextChoices):
    """Who the notification is addressed to."""

    ALL = "all", "All"
    ROLE = "role", "Role"
    SEGMENT = "segment", "Segment"
    SPECIFIC = "specific", "Specific"


class NotificationScheduleType(models.TextChoices):
    """When the notification is sent."""

    NOW = "now", "Now"
    SCHEDULED = "scheduled", "Scheduled"
    RECURRING = "recurring", "Recurring"


class NotificationStatus(models.TextChoices):
    """Lifecycle state of a Notification broadcast."""

    DRAFT = "draft", "Draft"
    SCHEDULED = "scheduled", "Scheduled"
    SENDING = "sending", "Sending"
    SENT = "sent", "Sent"
    FAILED = "failed", "Failed"


class NotificationDeliveryStatus(models.TextChoices):
    """Per-recipient delivery state."""

    QUEUED = "queued", "Queued"
    SENT = "sent", "Sent"
    DELIVERED = "delivered", "Delivered"
    OPENED = "opened", "Opened"
    FAILED = "failed", "Failed"
