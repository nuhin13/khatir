"""Django admin for the notifications domain.

Registers ``Notification``, ``NotificationDelivery``, and
``NotificationTemplate`` for super/ops admin staff access.
"""

from __future__ import annotations

from django.contrib import admin

from .models import Notification, NotificationDelivery, NotificationTemplate


class NotificationDeliveryInline(admin.TabularInline):  # type: ignore[type-arg]
    model = NotificationDelivery
    extra = 0
    readonly_fields = ("created_at", "updated_at", "delivered_at", "opened_at")
    fields = ("user", "channel", "status", "delivered_at", "opened_at", "error")


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = (
        "id",
        "title_en",
        "audience_type",
        "schedule_type",
        "status",
        "sent_count",
        "delivered_count",
        "opened_count",
        "created_at",
    )
    list_filter = ("status", "audience_type", "schedule_type")
    search_fields = ("title_en", "title_bn", "body_en", "body_bn")
    raw_id_fields = ("sender",)
    ordering = ("-created_at",)
    readonly_fields = (
        "created_at",
        "updated_at",
        "sent_count",
        "delivered_count",
        "opened_count",
    )
    inlines = (NotificationDeliveryInline,)


@admin.register(NotificationDelivery)
class NotificationDeliveryAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = (
        "id",
        "notification",
        "user",
        "channel",
        "status",
        "delivered_at",
        "opened_at",
        "created_at",
    )
    list_filter = ("status", "channel")
    raw_id_fields = ("notification", "user")
    ordering = ("-created_at",)
    readonly_fields = ("created_at", "updated_at", "delivered_at", "opened_at")


@admin.register(NotificationTemplate)
class NotificationTemplateAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = (
        "id",
        "key",
        "trigger_event",
        "active",
        "created_at",
    )
    list_filter = ("active",)
    search_fields = ("key", "trigger_event", "title_en", "title_bn")
    ordering = ("key",)
    readonly_fields = ("created_at", "updated_at")
