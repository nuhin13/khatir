"""Tests for the ``AdminUser`` model (T-001 §12).

Covers: create, disabled flag, TOTP encryption, role enum, field constraints,
soft-delete, separation from accounts.User, and index presence.
"""

from __future__ import annotations

import pytest
from django.contrib.auth.hashers import check_password
from django.db import IntegrityError, models

from khatir.admin_portal.models import AdminUser
from khatir.core.encryption import decrypt, encrypt
from khatir.core.enums import AdminRole

from .factories import AdminUserFactory

pytestmark = pytest.mark.django_db


# --- AdminUser create -------------------------------------------------------


def test_admin_user_create() -> None:
    admin: AdminUser = AdminUserFactory(name="Superuser One", role=AdminRole.SUPER)  # type: ignore[assignment]
    assert admin.pk is not None
    assert admin.email is not None
    assert admin.name == "Superuser One"
    assert admin.role == AdminRole.SUPER
    assert admin.disabled is False
    assert admin.last_login_at is None
    assert admin.totp_secret_enc is None
    assert admin.scope == {}
    assert str(admin) == f"Superuser One <{admin.email}>"


def test_admin_user_all_roles_valid() -> None:
    """Every AdminRole wire value produces a valid AdminUser."""
    for role in AdminRole:
        admin: AdminUser = AdminUserFactory(role=role)  # type: ignore[assignment]
        assert admin.role == role.value


# --- Disabled flag ----------------------------------------------------------


def test_disabled_flag_default_false() -> None:
    admin: AdminUser = AdminUserFactory()  # type: ignore[assignment]
    assert admin.disabled is False


def test_disabled_flag_can_be_set() -> None:
    admin: AdminUser = AdminUserFactory(disabled=True)  # type: ignore[assignment]
    assert admin.disabled is True
    admin.refresh_from_db()
    assert admin.disabled is True


def test_disabled_flag_toggle() -> None:
    admin: AdminUser = AdminUserFactory(disabled=False)  # type: ignore[assignment]
    admin.disabled = True
    admin.save(update_fields=["disabled", "updated_at"])
    admin.refresh_from_db()
    assert admin.disabled is True


# --- TOTP secret encrypted --------------------------------------------------


def test_totp_secret_encrypted() -> None:
    """TOTP secret is stored encrypted — decryption round-trips correctly."""
    plaintext_secret = "JBSWY3DPEHPK3PXP"
    encrypted = encrypt(plaintext_secret)
    admin: AdminUser = AdminUserFactory(totp_secret_enc=encrypted)  # type: ignore[assignment]
    admin.refresh_from_db()
    assert admin.totp_secret_enc is not None
    # The stored value must NOT be the plaintext secret.
    assert admin.totp_secret_enc != plaintext_secret
    # But decrypting must yield the original.
    assert decrypt(admin.totp_secret_enc) == plaintext_secret  # type: ignore[arg-type]


def test_totp_secret_enc_nullable_by_default() -> None:
    admin: AdminUser = AdminUserFactory()  # type: ignore[assignment]
    admin.refresh_from_db()
    assert admin.totp_secret_enc is None


def test_totp_secret_enc_is_charfield() -> None:
    field = AdminUser._meta.get_field("totp_secret_enc")
    assert isinstance(field, models.CharField)
    assert field.null is True


# --- Password hash ----------------------------------------------------------


def test_password_hash_is_hashed() -> None:
    admin: AdminUser = AdminUserFactory()  # type: ignore[assignment]
    # password_hash must not be a raw password (it must be a Django hash string).
    assert admin.password_hash.startswith(("pbkdf2_", "argon2", "bcrypt", "md5$"))


def test_password_hash_verifiable() -> None:
    admin: AdminUser = AdminUserFactory()  # type: ignore[assignment]
    assert check_password("testpassword123", admin.password_hash)


def test_password_hash_field_is_charfield() -> None:
    field = AdminUser._meta.get_field("password_hash")
    assert isinstance(field, models.CharField)


# --- Email uniqueness -------------------------------------------------------


def test_email_is_unique() -> None:
    field = AdminUser._meta.get_field("email")
    assert field.unique is True


def test_duplicate_email_raises() -> None:
    AdminUserFactory(email="dup@khatir.io")
    with pytest.raises(IntegrityError):
        AdminUserFactory(email="dup@khatir.io")


# --- Scope field ------------------------------------------------------------


def test_scope_default_empty_dict() -> None:
    admin: AdminUser = AdminUserFactory()  # type: ignore[assignment]
    admin.refresh_from_db()
    assert admin.scope == {}


def test_scope_stores_json() -> None:
    payload = {"tenants": [1, 2, 3], "buildings": "all"}
    admin: AdminUser = AdminUserFactory(scope=payload)  # type: ignore[assignment]
    admin.refresh_from_db()
    assert admin.scope == payload


def test_scope_is_jsonfield() -> None:
    field = AdminUser._meta.get_field("scope")
    assert isinstance(field, models.JSONField)


# --- Soft delete ------------------------------------------------------------


def test_admin_user_soft_delete() -> None:
    admin: AdminUser = AdminUserFactory()  # type: ignore[assignment]
    pk = admin.pk
    admin.delete()
    assert admin.is_deleted is True
    assert AdminUser.objects.filter(pk=pk).count() == 0
    assert AdminUser.all_objects.filter(pk=pk).count() == 1


def test_soft_delete_is_reversible() -> None:
    admin: AdminUser = AdminUserFactory()  # type: ignore[assignment]
    admin.delete()
    admin.restore()
    assert admin.is_deleted is False
    assert AdminUser.objects.filter(pk=admin.pk).count() == 1


# --- Separation from accounts.User ------------------------------------------


def test_admin_user_not_subclass_of_accounts_user() -> None:
    """AdminUser must NOT subclass the customer-facing User model."""
    from khatir.accounts.models import User

    assert not issubclass(AdminUser, User)


def test_admin_user_has_no_user_fk() -> None:
    """AdminUser must NOT have a FK into accounts.User."""
    from khatir.accounts.models import User

    fk_targets = [
        f.related_model
        for f in AdminUser._meta.get_fields()
        if isinstance(f, models.ForeignKey)
    ]
    assert User not in fk_targets


# --- AdminRole enum matches enums.md ----------------------------------------


def test_admin_role_values_match_spec() -> None:
    assert set(AdminRole.values) == {"super", "ops", "finance", "compliance", "support"}


# --- Indexes ----------------------------------------------------------------


def test_email_index_present() -> None:
    """email is unique=True which implicitly creates an index."""
    field = AdminUser._meta.get_field("email")
    assert field.unique is True


def test_created_at_has_auto_now_add() -> None:
    """created_at is set automatically via TimeStampedModel auto_now_add."""
    field = AdminUser._meta.get_field("created_at")
    assert isinstance(field, models.DateTimeField)
    assert field.auto_now_add is True
