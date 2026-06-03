"""Django admin for ``DMPFormRecord``.

The ``pdf_ref`` column is intentionally read-only — it points into encrypted
object storage and should not be edited by hand. ``generated_by`` is shown as
a raw FK (phone-number user) for traceability.
"""

from __future__ import annotations

from django.contrib import admin

from .models import DMPFormRecord


@admin.register(DMPFormRecord)
class DMPFormRecordAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = (
        "id",
        "tenant",
        "template_version",
        "generated_by",
        "generated_at",
        "created_at",
    )
    list_filter = ("template_version",)
    search_fields = ("tenant__name", "template_version", "pdf_ref")
    raw_id_fields = ("tenant", "generated_by")
    ordering = ("-generated_at",)
    readonly_fields = ("created_at", "updated_at", "pdf_ref")
