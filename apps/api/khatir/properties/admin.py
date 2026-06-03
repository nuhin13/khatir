"""Django admin registration for ``Building`` and ``Unit``."""

from __future__ import annotations

from django.contrib import admin

from .models import Building, Unit


@admin.register(Building)
class BuildingAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ("id", "name", "owner", "area", "created_at")
    list_filter = ("area",)
    search_fields = ("name", "address")
    raw_id_fields = ("owner",)
    ordering = ("-created_at",)
    readonly_fields = ("created_at", "updated_at", "deleted_at")


@admin.register(Unit)
class UnitAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ("id", "label", "building", "type", "rent", "status", "available_from")
    list_filter = ("type", "status")
    search_fields = ("label",)
    raw_id_fields = ("building",)
    ordering = ("building", "label")
    readonly_fields = ("created_at", "updated_at", "deleted_at")
