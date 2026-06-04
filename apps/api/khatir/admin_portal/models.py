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

from typing import Any, NoReturn

from django.db import models

from khatir.core.enums import AdminRole
from khatir.core.models import SoftDeleteModel, TimeStampedModel


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


class AdminAuditEntryQuerySet(models.QuerySet["AdminAuditEntry"]):
    """QuerySet that refuses bulk mutation — audit rows are append-only."""

    def update(self, *args: Any, **kwargs: Any) -> NoReturn:  # type: ignore[override]
        raise ImmutableAuditError("AdminAuditEntry rows are immutable; bulk update is forbidden.")

    def delete(self) -> NoReturn:  # type: ignore[override]
        raise ImmutableAuditError("AdminAuditEntry rows are immutable; bulk delete is forbidden.")


class AdminAuditEntryManager(models.Manager["AdminAuditEntry"]):
    """Manager exposing only append/read operations for the audit log."""

    def get_queryset(self) -> AdminAuditEntryQuerySet:
        return AdminAuditEntryQuerySet(self.model, using=self._db)


class ImmutableAuditError(RuntimeError):
    """Raised when code attempts to mutate or delete an audit entry."""


class AdminAuditEntry(TimeStampedModel):
    """An immutable record of a single admin-portal action — Domain 8.

    Every consequential admin write (toggle a flag, disable a user, change a
    config) is recorded here: *who* acted, *what* action, the affected entity,
    a *before*/*after* JSON diff, the request *IP*, and a free-text *reason*.

    Rows are **append-only**: once created they can never be updated or deleted
    (neither at the instance level nor via the queryset). Always write through
    :func:`khatir.admin_portal.audit.admin_audit`.
    """

    admin_user = models.ForeignKey(
        AdminUser,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="audit_entries",
        help_text="The staff account that performed the action (null for system actions).",
    )
    action = models.CharField(
        max_length=64,
        db_index=True,
        help_text="domain.verb action string, e.g. 'admin_user.disable', 'feature_flag.toggle'.",
    )
    entity_type = models.CharField(
        max_length=128,
        blank=True,
        default="",
        help_text="app_label.model_name of the affected entity (blank if not entity-scoped).",
    )
    entity_id = models.CharField(
        max_length=64,
        blank=True,
        default="",
        help_text="Primary key of the affected entity, as a string.",
    )
    before_json = models.JSONField(
        null=True,
        blank=True,
        default=None,
        help_text="Snapshot/diff of the affected fields before the change (null for creates).",
    )
    after_json = models.JSONField(
        null=True,
        blank=True,
        default=None,
        help_text="Snapshot/diff of the affected fields after the change (null for deletes).",
    )
    ip = models.GenericIPAddressField(
        null=True,
        blank=True,
        default=None,
        help_text="Source IP of the request that triggered the action.",
    )
    reason = models.CharField(
        max_length=255,
        blank=True,
        default="",
        help_text="Free-text justification supplied by the acting admin.",
    )

    objects = AdminAuditEntryManager()

    class Meta:
        verbose_name = "admin audit entry"
        verbose_name_plural = "admin audit entries"
        ordering = ("-created_at",)
        indexes = [
            models.Index(fields=["admin_user", "created_at"]),
            models.Index(fields=["action"]),
        ]

    def __str__(self) -> str:
        return (
            f"{self.action} by {self.admin_user_id or 'system'} "
            f"@ {self.created_at:%Y-%m-%d %H:%M}"
        )

    def save(self, *args: Any, **kwargs: Any) -> None:
        """Allow the initial insert only; reject any subsequent update."""
        if self.pk is not None:
            raise ImmutableAuditError("AdminAuditEntry rows are immutable; update is forbidden.")
        super().save(*args, **kwargs)

    def delete(self, *args: Any, **kwargs: Any) -> NoReturn:  # type: ignore[override]
        raise ImmutableAuditError("AdminAuditEntry rows are immutable; delete is forbidden.")
