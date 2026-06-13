"""Django admin for ``AIProvider`` and ``AIUsageLog``.

The ``api_key_enc`` field is **excluded** from all admin views — it must never
be shown or edited through the admin panel. Use the management command or a
dedicated API endpoint to rotate keys.
"""

from __future__ import annotations

from django.contrib import admin

from .models import AIProvider, AIUsageLog


@admin.register(AIProvider)
class AIProviderAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = (
        "id",
        "category",
        "provider_key",
        "model_name",
        "is_primary",
        "is_fallback",
        "active",
        "created_at",
    )
    list_filter = ("category", "is_primary", "is_fallback", "active")
    search_fields = ("provider_key", "model_name", "dpa_reference")
    ordering = ("category", "provider_key")
    readonly_fields = ("created_at", "updated_at")
    # api_key_enc is intentionally excluded — encrypted key must not be exposed.
    exclude = ("api_key_enc",)


@admin.register(AIUsageLog)
class AIUsageLogAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = (
        "id",
        "provider",
        "category",
        "success",
        "tokens_used",
        "cost_usd",
        "latency_ms",
        "created_at",
    )
    list_filter = ("category", "success")
    search_fields = ("provider__provider_key",)
    raw_id_fields = ("provider", "failover_from")
    ordering = ("-created_at",)
    readonly_fields = ("created_at", "updated_at")
