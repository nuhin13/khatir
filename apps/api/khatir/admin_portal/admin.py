"""Django admin for ``AdminUser``.

Registered for bootstrapping purposes only — the proper admin portal UI is
built in T-002 onward. The ``password_hash`` field is excluded from the change
form to prevent accidental plaintext writes; ``totp_secret_enc`` is similarly
excluded (encrypted; managed programmatically).
"""

from __future__ import annotations

from django.contrib import admin

from .models import AdminUser


@admin.register(AdminUser)
class AdminUserAdmin(admin.ModelAdmin):  # type: ignore[type-arg]
    list_display = (
        "id",
        "email",
        "name",
        "role",
        "disabled",
        "last_login_at",
        "created_at",
    )
    list_filter = ("role", "disabled")
    search_fields = ("email", "name")
    ordering = ("-created_at",)
    readonly_fields = ("created_at", "updated_at", "deleted_at", "last_login_at")
    # password_hash and totp_secret_enc are sensitive — never expose in the form.
    exclude = ("password_hash", "totp_secret_enc")
