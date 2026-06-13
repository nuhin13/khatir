"""Django admin for ``PricingTier`` and ``Subscription``.

PricingTier is admin-editable (the tier catalogue is never hardcoded).
Subscription rows show the landlord's current plan and billing status.
"""

from __future__ import annotations

from django.contrib import admin

from .models import PricingTier, Subscription


@admin.register(PricingTier)
class PricingTierAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = (
        "id",
        "key",
        "label",
        "tenant_min",
        "tenant_max",
        "monthly_price",
        "annual_price",
        "includes_verification",
        "included_credits",
        "active",
        "sort_order",
    )
    list_filter = ("active", "includes_verification")
    search_fields = ("key", "label", "label_bn")
    ordering = ("sort_order",)
    readonly_fields = ("created_at", "updated_at")


@admin.register(Subscription)
class SubscriptionAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = (
        "id",
        "user",
        "tier",
        "billing_cycle",
        "status",
        "start_at",
        "next_billing_at",
        "created_at",
    )
    list_filter = ("billing_cycle", "status")
    search_fields = ("user__phone", "user__name")
    raw_id_fields = ("user", "tier")
    ordering = ("-created_at",)
    readonly_fields = ("created_at", "updated_at")
