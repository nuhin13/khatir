from django.contrib import admin

from .models import ManagerOwnerLink


@admin.register(ManagerOwnerLink)
class ManagerOwnerLinkAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ("id", "manager", "owner", "status", "created_at")
    list_filter = ("status",)
    search_fields = ("manager__phone", "owner__phone", "manager__name", "owner__name")
    raw_id_fields = ("manager", "owner", "consent_record")
