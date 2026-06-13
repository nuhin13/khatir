from __future__ import annotations

from django.contrib import admin

from .models import CaretakerAssignment, VisitorEntry


@admin.register(CaretakerAssignment)
class CaretakerAssignmentAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ("id", "caretaker", "building", "status", "assigned_by", "created_at")
    list_filter = ("status",)
    raw_id_fields = ("caretaker", "building", "assigned_by")


@admin.register(VisitorEntry)
class VisitorEntryAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    # photo_ref_enc is intentionally never exposed — it is encrypted personal data.
    list_display = ("id", "visitor_name", "building", "unit", "status", "logged_by", "created_at")
    list_filter = ("status",)
    raw_id_fields = ("building", "unit", "logged_by")
