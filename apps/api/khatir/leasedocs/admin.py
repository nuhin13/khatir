"""Django admin for ``LeaseDocument`` (EPIC-18)."""

from __future__ import annotations

from django.contrib import admin

from .models import LeaseDocument


@admin.register(LeaseDocument)
class LeaseDocumentAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = (
        "id",
        "lease",
        "status",
        "model_used",
        "generated_by",
        "generated_at",
        "created_at",
    )
    list_filter = ("status",)
    search_fields = ("lease__id", "model_used", "pdf_ref")
    raw_id_fields = ("lease", "generated_by")
    ordering = ("-created_at",)
    readonly_fields = ("created_at", "updated_at", "deleted_at")
