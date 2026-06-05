"""Django admin for ``Warning``."""

from __future__ import annotations

from django.contrib import admin

from .models import Warning


@admin.register(Warning)
class WarningAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = (
        "id",
        "lease",
        "tenant",
        "landlord",
        "warning_type",
        "issued_at",
        "acknowledged_at",
    )
    list_filter = ("warning_type",)
    search_fields = ("reason",)
    raw_id_fields = ("lease", "tenant", "landlord")
    ordering = ("-issued_at",)
    readonly_fields = ("issued_at", "created_at", "updated_at", "deleted_at")
