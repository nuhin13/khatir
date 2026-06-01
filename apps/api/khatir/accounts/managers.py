"""Manager for the custom ``User`` model.

Phone is the login identity (``USERNAME_FIELD``) — there is no username. The
manager therefore creates users by ``phone`` rather than the Django default
``username``. Auth is OTP→JWT (see EPIC-01 T-003+), so ``create_user`` does not
require a password; the ``password`` field is kept (``AbstractBaseUser``
requires it) but normally unusable for human accounts.
"""

from __future__ import annotations

from typing import TYPE_CHECKING, Any

from django.contrib.auth.base_user import BaseUserManager

if TYPE_CHECKING:
    from .models import User


class UserManager(BaseUserManager["User"]):
    """Creates ``User`` rows keyed by phone instead of username."""

    use_in_migrations = True

    def _create_user(
        self, phone: str, password: str | None, **extra_fields: Any
    ) -> User:
        if not phone:
            raise ValueError("Users must have a phone number.")
        user = self.model(phone=phone, **extra_fields)
        # OTP is the auth path; password is optional and unusable when unset.
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_user(
        self, phone: str, password: str | None = None, **extra_fields: Any
    ) -> User:
        extra_fields.setdefault("is_staff", False)
        extra_fields.setdefault("is_superuser", False)
        return self._create_user(phone, password, **extra_fields)

    def create_superuser(
        self, phone: str, password: str | None = None, **extra_fields: Any
    ) -> User:
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        extra_fields.setdefault("is_active", True)

        if extra_fields.get("is_staff") is not True:
            raise ValueError("Superuser must have is_staff=True.")
        if extra_fields.get("is_superuser") is not True:
            raise ValueError("Superuser must have is_superuser=True.")

        return self._create_user(phone, password, **extra_fields)
