"""Django admin registration for ``User``.

The phone is shown **masked** (`****5678`) in list/detail so the admin never
casually exposes a full login identity. There is no password-set workflow here
because human auth is OTP-based.
"""

from __future__ import annotations

from django.contrib import admin
from django.http import HttpRequest

from .models import User


@admin.register(User)
class UserAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = ("id", "masked_phone", "name", "role", "language", "is_active", "is_staff")
    list_filter = ("role", "language", "is_active", "is_staff")
    search_fields = ("name",)
    ordering = ("-created_at",)
    readonly_fields = ("masked_phone", "last_login_at", "created_at", "updated_at")
    exclude = ("password",)

    @admin.display(description="phone")
    def masked_phone(self, obj: User) -> str:
        return obj.masked_phone

    def has_add_permission(self, request: HttpRequest) -> bool:
        # Accounts are created via the OTP onboarding flow, not by hand.
        return False
