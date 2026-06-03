"""Django admin for ``FeatureFlag`` and ``KillSwitchEvent``.

``KillSwitchEvent`` rows are append-only: the admin marks them fully
read-only and hides the "delete" action so no staff member can accidentally
violate the audit requirement.
"""

from __future__ import annotations

from django.contrib import admin
from django.http import HttpRequest

from .models import FeatureFlag, KillSwitchEvent


@admin.register(FeatureFlag)
class FeatureFlagAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = (
        "key",
        "scope",
        "enabled",
        "updated_by",
        "updated_at",
    )
    list_filter = ("scope", "enabled")
    search_fields = ("key", "description")
    raw_id_fields = ("updated_by",)
    ordering = ("key",)
    readonly_fields = ("created_at", "updated_at")


@admin.register(KillSwitchEvent)
class KillSwitchEventAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = (
        "id",
        "switch_key",
        "action",
        "admin_user",
        "lawyer_reference",
        "created_at",
    )
    list_filter = ("action",)
    search_fields = ("switch_key", "reason", "lawyer_reference")
    raw_id_fields = ("admin_user",)
    ordering = ("-created_at",)
    # All fields are read-only — these are immutable audit records.
    readonly_fields = (
        "switch_key",
        "action",
        "reason",
        "admin_user",
        "lawyer_reference",
        "created_at",
    )

    def has_add_permission(self, request: HttpRequest) -> bool:
        # New events are created by the kill-switch service, not via the admin form.
        return False

    def has_change_permission(
        self, request: HttpRequest, obj: object = None
    ) -> bool:
        return False

    def has_delete_permission(
        self, request: HttpRequest, obj: object = None
    ) -> bool:
        return False
