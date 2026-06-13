"""Django admin for ``VerificationLog`` — result only, read-only.

Verification logs are append-only by design (audit trail). They are shown
read-only — no add/change/delete — and never expose any raw EC data, only the
boolean-style ``result`` and the opaque ``provider_ref``.
"""

from __future__ import annotations

from django.contrib import admin

from .models import VerificationLog


@admin.register(VerificationLog)
class VerificationLogAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = (
        "id",
        "tenant",
        "result",
        "requested_by",
        "provider_ref",
        "created_at",
    )
    list_filter = ("result",)
    search_fields = ("provider_ref",)
    raw_id_fields = ("tenant", "requested_by", "consent_record")
    ordering = ("-created_at",)
    readonly_fields = ("created_at", "updated_at")

    # Verification logs are append-only — no mutation via admin.
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
