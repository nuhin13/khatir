"""Django admin for ``MaintenanceRequest`` and ``Expense``."""

from __future__ import annotations

from django.contrib import admin

from .models import Expense, MaintenanceRequest


@admin.register(MaintenanceRequest)
class MaintenanceRequestAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = (
        "id",
        "unit",
        "category",
        "status",
        "resolution_cost",
        "created_at",
    )
    list_filter = ("status", "category")
    search_fields = ("description", "resolution_note")
    raw_id_fields = ("unit", "lease")
    ordering = ("-created_at",)
    readonly_fields = ("created_at", "updated_at", "deleted_at")


@admin.register(Expense)
class ExpenseAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = (
        "id",
        "unit",
        "category",
        "amount",
        "date",
        "source",
        "created_at",
    )
    list_filter = ("category", "source")
    search_fields = ("note",)
    raw_id_fields = ("unit",)
    ordering = ("-date", "-created_at")
    readonly_fields = ("created_at", "updated_at", "deleted_at")
