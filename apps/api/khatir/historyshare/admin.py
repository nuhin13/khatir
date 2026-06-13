"""Django admin for ``HistoryShare`` — read-only.

Shares are tenant-initiated and consent-gated; staff inspect them but never
create or edit them here (and never to drive a landlord-initiated lookup).
"""

from __future__ import annotations

from django.contrib import admin

from .models import HistoryShare


@admin.register(HistoryShare)
class HistoryShareAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = (
        "id",
        "tenant",
        "recipient_landlord",
        "expires_at",
        "revoked_at",
        "created_at",
    )
    list_filter = ("revoked_at",)
    search_fields = ("tenant__name", "recipient_landlord__phone")
    raw_id_fields = ("tenant", "recipient_landlord", "consent_record")
    ordering = ("-created_at",)
    readonly_fields = ("created_at", "updated_at", "factual_stats")

    def has_add_permission(self, request: object) -> bool:  # type: ignore[override]
        return False

    def has_change_permission(  # type: ignore[override]
        self, request: object, obj: object = None
    ) -> bool:
        return False
