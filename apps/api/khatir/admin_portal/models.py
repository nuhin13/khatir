"""Admin portal domain models — Domain 8 of ``06_database_schema.md``.

``AdminUser`` is a **completely separate** table from the customer-facing
``accounts.User``. It has its own email+password auth (Argon2/bcrypt/PBKDF2 via
Django's ``make_password``/``check_password``), an optional TOTP secret stored
**encrypted** at rest via ``core.encryption``, and an ``AdminRole`` that
restricts what the staff member may do.

This model does NOT subclass ``AbstractBaseUser`` or have any FK into the
customer ``User`` table — staff auth is handled by a dedicated admin-portal
authentication flow (T-002).
"""

from __future__ import annotations

from django.db import models

from khatir.core.enums import AdminRole
from khatir.core.models import SoftDeleteModel


class AdminUser(SoftDeleteModel):
    """An internal staff account — separate from the customer-facing ``User``.

    ``password_hash`` stores the Django-hashed password string (compatible with
    ``django.contrib.auth.hashers.check_password``). In tests the MD5 hasher is
    active; in production ``Argon2PasswordHasher`` or ``BCryptSHA256PasswordHasher``
    should be configured in ``PASSWORD_HASHERS``.

    ``totp_secret_enc`` holds the TOTP base32 secret **encrypted** via
    ``core.encryption.encrypt``/``decrypt`` (Fernet). ``None`` means MFA has not
    yet been set up for this account.
    """

    email = models.EmailField(
        unique=True,
        db_index=True,
        help_text="Login identity — unique across all admin staff accounts.",
    )
    name = models.CharField(
        max_length=120,
        help_text="Display name.",
    )
    password_hash = models.CharField(
        max_length=255,
        help_text=(
            "Django-format hashed password (make_password / check_password). "
            "Never store plaintext. Use Argon2 or bcrypt in production."
        ),
    )
    totp_secret_enc = models.CharField(  # noqa: DJ001
        max_length=512,
        null=True,
        blank=True,
        default=None,
        help_text=(
            "TOTP base32 secret, encrypted at rest via core.encryption. "
            "None until the staff member completes MFA setup."
        ),
    )
    role = models.CharField(
        max_length=16,
        choices=AdminRole.choices,
        default=AdminRole.SUPPORT,
        db_index=True,
        help_text="super / ops / finance / compliance / support.",
    )
    scope = models.JSONField(
        default=dict,
        blank=True,
        help_text=(
            "Optional JSON payload that further restricts what this admin may "
            "access (e.g. specific tenant IDs, buildings). Empty dict = no extra restriction."
        ),
    )
    disabled = models.BooleanField(
        default=False,
        db_index=True,
        help_text="Disabled accounts cannot log in to the admin portal.",
    )
    last_login_at = models.DateTimeField(
        null=True,
        blank=True,
        default=None,
        help_text="UTC timestamp of the last successful admin login.",
    )

    class Meta:
        verbose_name = "admin user"
        verbose_name_plural = "admin users"
        ordering = ("-created_at",)
        indexes = [
            models.Index(fields=["role"]),
            models.Index(fields=["disabled"]),
        ]

    def __str__(self) -> str:
        return f"{self.name} <{self.email}>"
