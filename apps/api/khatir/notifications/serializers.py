"""Serializers for the admin notification-template endpoints — EPIC-15.T-008."""

from __future__ import annotations

from rest_framework import serializers

from .models import NotificationTemplate


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
