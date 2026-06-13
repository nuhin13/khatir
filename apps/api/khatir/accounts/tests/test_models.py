"""Tests for the custom ``User`` model and its manager (T-002 test plan §12)."""

from __future__ import annotations

import pytest
from django.contrib.auth import get_user_model
from django.db import IntegrityError

from khatir.accounts.enums import Language, Role
from khatir.accounts.models import User

from .factories import UserFactory

pytestmark = pytest.mark.django_db


def test_auth_user_model_is_accounts_user() -> None:
    assert get_user_model() is User


def test_create_user_by_phone_no_password_required() -> None:
    user = User.objects.create_user(phone="+8801712345678")
    assert user.phone == "+8801712345678"
    assert user.pk is not None
    assert user.is_staff is False
    assert user.is_superuser is False
    assert user.is_active is True
    # No password was supplied → the account has no usable password.
    assert user.has_usable_password() is False


def test_create_superuser_flags() -> None:
    admin = User.objects.create_superuser(phone="+8801799999999")
    assert admin.is_staff is True
    assert admin.is_superuser is True
    assert admin.is_active is True


def test_create_superuser_rejects_non_staff() -> None:
    with pytest.raises(ValueError, match="is_staff=True"):
        User.objects.create_superuser(phone="+8801711111111", is_staff=False)


def test_create_superuser_rejects_non_superuser() -> None:
    with pytest.raises(ValueError, match="is_superuser=True"):
        User.objects.create_superuser(phone="+8801722222222", is_superuser=False)


def test_create_user_requires_phone() -> None:
    with pytest.raises(ValueError, match="phone number"):
        User.objects.create_user(phone="")


def test_phone_must_be_unique() -> None:
    User.objects.create_user(phone="+8801733333333")
    with pytest.raises(IntegrityError):
        User.objects.create_user(phone="+8801733333333")


def test_defaults_role_and_language() -> None:
    user = User.objects.create_user(phone="+8801744444444")
    assert user.role == Role.LANDLORD
    assert user.language == Language.BN
    assert user.name == ""
    assert user.last_login_at is None


def test_username_field_is_phone() -> None:
    assert User.USERNAME_FIELD == "phone"
    assert User.REQUIRED_FIELDS == []


def test_masked_phone_hides_all_but_last_four() -> None:
    user = User.objects.create_user(phone="+8801712345678")
    assert user.masked_phone == "**********5678"
    assert user.masked_phone.endswith("5678")
    assert "+8801712345678" not in user.masked_phone


def test_timestamps_inherited() -> None:
    user = User.objects.create_user(phone="+8801755555555")
    assert user.created_at is not None
    assert user.updated_at is not None


def test_factory_builds_valid_user() -> None:
    user: User = UserFactory()  # type: ignore[assignment]
    assert user.pk is not None
    assert user.role == Role.LANDLORD
    assert user.phone.startswith("+88017")
