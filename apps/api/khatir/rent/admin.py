"""Django admin for ``RentRequest``, ``PaymentProof`` and ``Payment``."""

from __future__ import annotations

from django.contrib import admin

from .models import Payment, PaymentProof, RentRequest


class PaymentProofInline(admin.TabularInline):  # type: ignore[type-arg]
    model = PaymentProof
    extra = 0
    readonly_fields = ("created_at", "updated_at")
    fields = ("type", "value", "photo_ref", "submitted_at")


class PaymentInline(admin.TabularInline):  # type: ignore[type-arg]
    model = Payment
    extra = 0
    readonly_fields = ("created_at", "updated_at")
    fields = ("verified_at", "verified_by", "receipt_ref")
    raw_id_fields = ("verified_by",)


@admin.register(RentRequest)
class RentRequestAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = (
        "id",
        "lease",
        "rent_schedule",
        "period",
        "amount",
        "sent_via",
        "status",
        "sent_at",
        "created_at",
    )
    list_filter = ("status", "sent_via")
    search_fields = ("link_token", "period", "lease__id")
    raw_id_fields = ("lease", "rent_schedule")
    ordering = ("-created_at",)
    readonly_fields = ("created_at", "updated_at")
    inlines = (PaymentProofInline, PaymentInline)


@admin.register(PaymentProof)
class PaymentProofAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = (
        "id",
        "rent_request",
        "type",
        "value",
        "submitted_at",
        "created_at",
    )
    list_filter = ("type",)
    search_fields = ("value", "rent_request__id")
    raw_id_fields = ("rent_request",)
    ordering = ("-created_at",)
    readonly_fields = ("created_at", "updated_at")


@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = (
        "id",
        "rent_request",
        "verified_by",
        "verified_at",
        "receipt_ref",
        "created_at",
    )
    search_fields = ("rent_request__id", "verified_by__phone", "receipt_ref")
    raw_id_fields = ("rent_request", "verified_by")
    ordering = ("-created_at",)
    readonly_fields = ("created_at", "updated_at")
