"""Django admin for ``GovExport``.

``file_ref`` is intentionally read-only — it points into encrypted object
storage and should not be edited by hand. ``landlord`` is shown as a raw FK
(phone-number user) for traceability.
"""

from __future__ import annotations

from django.contrib import admin

from .models import GovExport


@admin.register(GovExport)
class GovExportAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = (
        "id",
        "landlord",
        "period",
        "format_version",
        "record_count",
        "status",
        "created_at",
    )
    list_filter = ("status", "format_version", "period")
    search_fields = ("landlord__phone", "period", "format_version", "file_ref")
    raw_id_fields = ("landlord",)
    ordering = ("-created_at",)
    readonly_fields = ("created_at", "updated_at", "file_ref")
