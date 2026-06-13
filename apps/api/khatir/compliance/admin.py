"""Django admin for ``ConsentRecord`` and ``DataRequest``.

Consent records are shown read-only in the admin — no add/change/delete
because they are append-only by design (PDPA regulatory requirement).
"""

from __future__ import annotations

from django.contrib import admin

from .models import ConsentRecord, DataRequest


@admin.register(ConsentRecord)
class ConsentRecordAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = (
        "id",
        "user",
        "consent_type",
        "granted_at",
        "revoked_at",
        "expires_at",
        "created_at",
    )
    list_filter = ("consent_type",)
    search_fields = ("user__phone",)
    raw_id_fields = ("user",)
    ordering = ("-granted_at",)
    readonly_fields = ("created_at", "updated_at")

    # Consent records are append-only — no mutation via admin.
    def has_add_permission(self, request: object) -> bool:  # type: ignore[override]
        return False

    def has_change_permission(  # type: ignore[override]
        self, request: object, obj: object = None
    ) -> bool:
        return False

    def has_delete_permission(  # type: ignore[override]
        self, request: object, obj: object = None
    ) -> bool:
        return False


@admin.register(DataRequest)
class DataRequestAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = (
        "id",
        "user",
        "request_type",
        "status",
        "sla_due",
        "completed_at",
        "handled_by",
        "created_at",
    )
    list_filter = ("request_type", "status")
    search_fields = ("user__phone",)
    raw_id_fields = ("user", "handled_by")
    ordering = ("-created_at",)
    readonly_fields = ("created_at", "updated_at")
