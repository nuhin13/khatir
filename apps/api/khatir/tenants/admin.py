"""Django admin for ``Tenant`` and ``TenantFamilyMember``.

Admins only ever see the **masked** NID — the encrypted column is hidden and
the plaintext is never materialised, per the Domain-3 privacy rule.
"""

from __future__ import annotations

from django.contrib import admin

from .models import Tenant, TenantFamilyMember


class TenantFamilyMemberInline(admin.TabularInline):  # type: ignore[type-arg]
    model = TenantFamilyMember
    extra = 0


@admin.register(Tenant)
class TenantAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = (
        "id",
        "name",
        "nid_number_masked",
        "verification_status",
        "is_app_user",
        "created_at",
    )
    list_filter = ("verification_status", "is_app_user")
    search_fields = ("name", "nid_number_masked")
    raw_id_fields = ("linked_user",)
    ordering = ("-created_at",)
    readonly_fields = ("created_at", "updated_at", "deleted_at")
    # ``nid_number_enc`` is intentionally excluded — masked display only.
    exclude = ("nid_number_enc",)
    inlines = (TenantFamilyMemberInline,)


@admin.register(TenantFamilyMember)
class TenantFamilyMemberAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ("id", "name", "relation", "tenant", "created_at")
    search_fields = ("name", "relation")
    raw_id_fields = ("tenant",)
    ordering = ("tenant", "name")
    readonly_fields = ("created_at", "updated_at")
