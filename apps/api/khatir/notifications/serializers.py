"""Serializers for the admin notification endpoints — EPIC-15.T-007 / T-008.

T-008 covers :class:`NotificationTemplateSerializer` (template CRUD); T-007 adds
the broadcast read serializers (:class:`NotificationSerializer`,
:class:`NotificationDeliverySerializer`, :class:`NotificationDetailSerializer`)
and the write/compose input serializer (:class:`NotificationComposeSerializer`).
"""

from __future__ import annotations

from rest_framework import serializers

from khatir.notifications.enums import (
    NotificationAudienceType,
    NotificationScheduleType,
)

from .models import Notification, NotificationDelivery, NotificationTemplate


class NotificationTemplateSerializer(
    serializers.ModelSerializer[NotificationTemplate]
):
    """Read/write projection of a :class:`NotificationTemplate`.

    ``key`` and ``trigger_event`` are settable on create but **immutable**
    thereafter — the template's identity and the internal event that fires it
    are stable contracts code depends on (task §1). Editable fields are the
    presentation pieces: bilingual title/body, ``channels``, ``variables`` and
    the ``active`` flag.
    """

    class Meta:
        model = NotificationTemplate
        fields = (
            "id",
            "key",
            "trigger_event",
            "channels",
            "title_en",
            "title_bn",
            "body_en",
            "body_bn",
            "variables",
            "active",
            "created_at",
            "updated_at",
        )
        read_only_fields = (
            "id",
            "created_at",
            "updated_at",
        )

    def update(
        self,
        instance: NotificationTemplate,
        validated_data: dict,
    ) -> NotificationTemplate:
        # ``key`` and ``trigger_event`` are immutable after creation.
        validated_data.pop("key", None)
        validated_data.pop("trigger_event", None)
        return super().update(instance, validated_data)


class NotificationDeliverySerializer(
    serializers.ModelSerializer[NotificationDelivery]
):
    """Read-only projection of a single per-recipient delivery row."""

    class Meta:
        model = NotificationDelivery
        fields = (
            "id",
            "user",
            "channel",
            "status",
            "delivered_at",
            "opened_at",
            "error",
            "created_at",
            "updated_at",
        )
        read_only_fields = fields


class NotificationSerializer(serializers.ModelSerializer[Notification]):
    """Read projection of a broadcast for the list view (no per-recipient rows)."""

    class Meta:
        model = Notification
        fields = (
            "id",
            "sender",
            "audience_type",
            "audience_filter",
            "channels",
            "title_en",
            "title_bn",
            "body_en",
            "body_bn",
            "schedule_type",
            "scheduled_at",
            "status",
            "sent_count",
            "delivered_count",
            "opened_count",
            "created_at",
            "updated_at",
        )
        read_only_fields = fields


class NotificationDetailSerializer(NotificationSerializer):
    """Broadcast detail view — embeds the per-recipient delivery rows."""

    deliveries = NotificationDeliverySerializer(many=True, read_only=True)

    class Meta(NotificationSerializer.Meta):
        fields = (*NotificationSerializer.Meta.fields, "deliveries")
        read_only_fields = fields


class NotificationComposeSerializer(serializers.Serializer):
    """Validate the compose payload before handing it to the service.

    The heavy domain validation (audience filter shape, channel values, schedule
    rules) lives in :func:`khatir.notifications.services.compose_notification`;
    this serializer only enforces the wire contract (required fields, choices).
    """

    audience_type = serializers.ChoiceField(
        choices=NotificationAudienceType.choices,
        default=NotificationAudienceType.ALL,
    )
    audience_filter = serializers.DictField(required=False, default=dict)
    channels = serializers.ListField(
        child=serializers.CharField(), allow_empty=False
    )
    title_en = serializers.CharField(max_length=255)
    title_bn = serializers.CharField(max_length=255)
    body_en = serializers.CharField()
    body_bn = serializers.CharField()
    schedule_type = serializers.ChoiceField(
        choices=NotificationScheduleType.choices,
        default=NotificationScheduleType.NOW,
    )
    scheduled_at = serializers.DateTimeField(required=False, allow_null=True)
    recurrence = serializers.DictField(required=False, allow_null=True)
