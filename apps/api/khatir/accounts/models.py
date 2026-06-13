"""The custom ``User`` model — Domain 1 of ``06_database_schema.md``.

One ``User`` table serves every human role (landlord / manager / tenant /
caretaker / admin). The **phone number is the login identity** — there is no
username, and passwords are unused because authentication is OTP→JWT. This is
wired in as ``AUTH_USER_MODEL`` before any other domain model so that all
``ForeignKey(settings.AUTH_USER_MODEL)`` references resolve to it.
"""

from __future__ import annotations

from typing import ClassVar

from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.db import models

from khatir.core.models import TimeStampedModel

from .enums import Language, Role
from .managers import UserManager


class User(AbstractBaseUser, PermissionsMixin, TimeStampedModel):
    """A human account, identified by phone, scoped by ``role``."""

    phone = models.CharField(
        max_length=20,
        unique=True,
        help_text="Login identity in E.164 format, e.g. +8801712345678.",
    )
    role = models.CharField(
        max_length=16,
        choices=Role.choices,
        default=Role.LANDLORD,
        db_index=True,
        help_text="Decides which app experience this user gets. Set in EPIC-02.",
    )
    name = models.CharField(max_length=120, blank=True, default="")
    language = models.CharField(
        max_length=2,
        choices=Language.choices,
        default=Language.BN,
        help_text="Drives all UI text for this user.",
    )

    is_active = models.BooleanField(
        default=True, help_text="Disabled accounts cannot log in."
    )
    is_staff = models.BooleanField(
        default=False, help_text="Can access the Django admin."
    )
    last_login_at = models.DateTimeField(
        null=True, blank=True, default=None, help_text="For support/security visibility."
    )

    objects = UserManager()

    USERNAME_FIELD: ClassVar[str] = "phone"
    REQUIRED_FIELDS: ClassVar[list[str]] = []

    class Meta:
        verbose_name = "user"
        verbose_name_plural = "users"
        ordering = ("-created_at",)

    def __str__(self) -> str:
        return f"{self.name or 'User'} ({self.masked_phone})"

    @property
    def masked_phone(self) -> str:
        """Phone with all but the last four digits masked (never log raw phone)."""
        if len(self.phone) <= 4:
            return self.phone
        return f"{'*' * (len(self.phone) - 4)}{self.phone[-4:]}"
