"""Django admin for ``ChatConversation`` and ``ChatMessage``."""

from __future__ import annotations

from django.contrib import admin

from .models import ChatConversation, ChatMessage


@admin.register(ChatConversation)
class ChatConversationAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ("id", "user", "started_at", "created_at")
    raw_id_fields = ("user",)
    ordering = ("-started_at",)
    readonly_fields = ("created_at", "updated_at")


@admin.register(ChatMessage)
class ChatMessageAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ("id", "conversation", "role", "created_at")
    list_filter = ("role",)
    raw_id_fields = ("conversation",)
    ordering = ("-created_at",)
    readonly_fields = ("created_at", "updated_at")
