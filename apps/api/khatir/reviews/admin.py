"""Django admin for ``Review``.

Admin is for support/compliance staff only. Reviews are private by construction;
nothing here exposes a cross-lease or public lookup.
"""

from __future__ import annotations

from django.contrib import admin

from .models import Review


@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = (
        "id",
        "lease",
        "reviewer",
        "reviewee",
        "rating",
        "visibility",
        "revealed_at",
        "created_at",
    )
    list_filter = ("visibility",)
    search_fields = ("lease__id", "reviewer__phone", "reviewee__phone")
    raw_id_fields = ("lease", "reviewer", "reviewee", "consent_record")
    ordering = ("-created_at",)
    readonly_fields = ("created_at", "updated_at", "deleted_at", "revealed_at")
