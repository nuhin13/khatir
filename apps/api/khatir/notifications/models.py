"""Notifications domain models — Domain 8 of ``06_database_schema.md``.

Three models cover the platform notification system:

- ``Notification`` — a broadcast authored by an admin (sender), addressed to an
  audience (all / role / segment / specific), delivered via one or more channels.
  Bilingual title/body (``_en`` / ``_bn`` suffixes), schedule, status, and
  aggregate sent/delivered/opened counts.

- ``NotificationDelivery`` — one row per recipient × channel; tracks per-user
  delivery state, timestamps, and any delivery error.

- ``NotificationTemplate`` — reusable, auto-triggered message stubs (e.g. rent
  reminder, welcome); identified by a stable ``key``, linked to a ``trigger_event``,
  with bilingual title/body and a ``variables`` list so callers know which
  placeholders to fill.

``Notification`` uses ``TimeStampedModel`` (not ``SoftDeleteModel``) because
broadcast records are append-only ledger rows that should not be soft-deleted.
``NotificationDelivery`` and ``NotificationTemplate`` similarly use
``TimeStampedModel``.

The ``sender`` FK points to ``admin_portal.AdminUser`` — broadcasts are authored
by back-office admins, never customer-facing users.
"""

from __future__ import annotations

from django.conf import settings
from django.db import models

from khatir.core.enums import Channel
from khatir.core.models import TimeStampedModel

from .enums import (
    NotificationAudienceType,
    NotificationDeliveryStatus,
    NotificationScheduleType,
    NotificationStatus,
)


class Notification(TimeStampedModel):
    """A broadcast authored by an admin and sent to an audience.

    ``channels`` is a JSON array of ``Channel`` wire values (e.g.
    ``["inapp", "sms"]``). ``audience_filter`` is an opaque JSON payload
    whose shape depends on ``audience_type`` (e.g. a list of user IDs for
    ``specific``, a role string for ``role``).
    """

    sender = models.ForeignKey(
        "admin_portal.AdminUser",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        default=None,
        related_name="sent_notifications",
        help_text=(
            "Admin user who authored this broadcast. "
            "Nullable to allow system-generated notifications."
        ),
    )
    audience_type = models.CharField(
        max_length=16,
        choices=NotificationAudienceType.choices,
        default=NotificationAudienceType.ALL,
        db_index=True,
        help_text="all / role / segment / specific.",
    )
    audience_filter = models.JSONField(
        default=dict,
        blank=True,
        help_text=(
            "Opaque filter payload; shape varies by audience_type. "
            "Empty dict for 'all'."
        ),
    )
    channels = models.JSONField(
        default=list,
        help_text="List of Channel wire values, e.g. ['inapp', 'sms'].",
    )
    title_en = models.CharField(
        max_length=255,
        help_text="Notification title in English.",
    )
    title_bn = models.CharField(
        max_length=255,
        help_text="Notification title in Bangla.",
    )
    body_en = models.TextField(
        help_text="Notification body in English.",
    )
    body_bn = models.TextField(
        help_text="Notification body in Bangla.",
    )
    schedule_type = models.CharField(
        max_length=16,
        choices=NotificationScheduleType.choices,
        default=NotificationScheduleType.NOW,
        db_index=True,
        help_text="now / scheduled / recurring.",
    )
    scheduled_at = models.DateTimeField(
        null=True,
        blank=True,
        default=None,
        help_text="When to send (only for schedule_type=scheduled/recurring).",
    )
    status = models.CharField(
        max_length=16,
        choices=NotificationStatus.choices,
        default=NotificationStatus.DRAFT,
        db_index=True,
        help_text="draft / scheduled / sending / sent / failed.",
    )
    sent_count = models.PositiveIntegerField(
        default=0,
        help_text="Number of delivery rows in state >= sent.",
    )
    delivered_count = models.PositiveIntegerField(
        default=0,
        help_text="Number of delivery rows in state >= delivered.",
    )
    opened_count = models.PositiveIntegerField(
        default=0,
        help_text="Number of delivery rows in state = opened.",
    )

    class Meta:
        ordering = ("-created_at",)
        indexes = [
            models.Index(fields=["status"]),
            models.Index(fields=["audience_type"]),
            models.Index(fields=["schedule_type"]),
        ]

    def __str__(self) -> str:
        return f"[{self.status}] {self.title_en}"


class NotificationDelivery(TimeStampedModel):
    """One delivery row per recipient × channel for a Notification.

    ``notification`` and ``user`` together with ``channel`` form the natural
    composite key. ``status`` tracks progress from queued through to delivered,
    opened, or failed.
    """

    notification = models.ForeignKey(
        Notification,
        on_delete=models.CASCADE,
        related_name="deliveries",
        help_text="The parent broadcast.",
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="notification_deliveries",
        help_text="The recipient.",
    )
    channel = models.CharField(
        max_length=16,
        choices=Channel.choices,
        db_index=True,
        help_text="inapp / whatsapp / sms / email.",
    )
    status = models.CharField(
        max_length=16,
        choices=NotificationDeliveryStatus.choices,
        default=NotificationDeliveryStatus.QUEUED,
        db_index=True,
        help_text="queued / sent / delivered / opened / failed.",
    )
    delivered_at = models.DateTimeField(
        null=True,
        blank=True,
        default=None,
        help_text="When the channel confirmed delivery.",
    )
    opened_at = models.DateTimeField(
        null=True,
        blank=True,
        default=None,
        help_text="When the recipient opened / acknowledged the notification.",
    )
    error = models.TextField(
        blank=True,
        default="",
        help_text="Error message if status = failed.",
    )

    class Meta:
        ordering = ("-created_at",)
        indexes = [
            models.Index(fields=["notification", "status"]),
            models.Index(fields=["user", "status"]),
        ]

    def __str__(self) -> str:
        return f"Delivery #{self.pk} [{self.status}] → user {self.user_id} via {self.channel}"


class NotificationTemplate(TimeStampedModel):
    """A reusable, auto-triggered notification blueprint.

    Identified by a stable ``key`` (e.g. ``rent_reminder``, ``welcome``).
    ``trigger_event`` is the internal event name that should fire this template.
    ``channels`` and ``variables`` are JSON arrays. ``active`` lets admins
    disable a template without deleting it.
    """

    key = models.CharField(
        max_length=128,
        unique=True,
        db_index=True,
        help_text="Stable identifier, e.g. 'rent_reminder'. Unique across templates.",
    )
    trigger_event = models.CharField(
        max_length=128,
        blank=True,
        default="",
        help_text="Internal event name that fires this template (e.g. 'rent.due').",
    )
    channels = models.JSONField(
        default=list,
        help_text="List of Channel wire values this template targets.",
    )
    title_en = models.CharField(
        max_length=255,
        help_text="Template title in English.",
    )
    title_bn = models.CharField(
        max_length=255,
        help_text="Template title in Bangla.",
    )
    body_en = models.TextField(
        help_text="Template body in English (may contain {variable} placeholders).",
    )
    body_bn = models.TextField(
        help_text="Template body in Bangla (may contain {variable} placeholders).",
    )
    variables = models.JSONField(
        default=list,
        blank=True,
        help_text="List of placeholder variable names, e.g. ['tenant_name', 'amount'].",
    )
    active = models.BooleanField(
        default=True,
        db_index=True,
        help_text="Disabled templates are not fired by the notification sender.",
    )

    class Meta:
        ordering = ("key",)
        indexes = [
            models.Index(fields=["trigger_event"]),
            models.Index(fields=["active"]),
        ]

    def __str__(self) -> str:
        return self.key
