"""Django admin for ``Lease`` and ``RentSchedule``."""

from __future__ import annotations

from django.contrib import admin

from .models import Lease, RentSchedule


class RentScheduleInline(admin.TabularInline):  # type: ignore[type-arg]
    model = RentSchedule
    extra = 0
    readonly_fields = ("created_at", "updated_at")
    fields = ("period", "due_day", "due_date", "amount", "status", "sent_at")


@admin.register(Lease)
class LeaseAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = (
        "id",
        "unit",
        "tenant",
        "landlord",
        "start_date",
        "end_date",
        "rent",
        "status",
        "created_at",
    )
    list_filter = ("status",)
    search_fields = ("unit__label", "tenant__name", "landlord__phone")
    raw_id_fields = ("unit", "tenant", "landlord")
    ordering = ("-created_at",)
    readonly_fields = ("created_at", "updated_at", "deleted_at")
    inlines = (RentScheduleInline,)


@admin.register(RentSchedule)
class RentScheduleAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = (
        "id",
        "lease",
        "period",
        "due_date",
        "amount",
        "status",
        "sent_at",
    )
    list_filter = ("status",)
    search_fields = ("period", "lease__id")
    raw_id_fields = ("lease",)
    ordering = ("lease", "period")
    readonly_fields = ("created_at", "updated_at")
