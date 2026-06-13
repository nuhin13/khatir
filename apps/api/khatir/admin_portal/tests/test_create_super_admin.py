"""Tests for the ``create_super_admin`` management command (T-012 §12).

Covers: creates a super-admin with hashed password + encrypted TOTP secret and
an audit row; prints the temp password and otpauth URI once; idempotent re-run
makes no changes; dry-run writes nothing.
"""

from __future__ import annotations

from io import StringIO

import pyotp
import pytest
from django.contrib.auth.hashers import check_password
from django.core.management import call_command

from khatir.admin_portal.models import AdminAuditEntry, AdminUser
from khatir.core.encryption import decrypt
from khatir.core.enums import AdminRole

pytestmark = pytest.mark.django_db

_EMAIL = "founder@khatir.io"


def _run(**kwargs: object) -> str:
    out = StringIO()
    call_command("create_super_admin", stdout=out, **kwargs)
    return out.getvalue()


def test_command_creates_user() -> None:
    output = _run(email=_EMAIL, name="Founder One")

    admin = AdminUser.objects.get(email=_EMAIL)
    assert admin.role == AdminRole.SUPER
    assert admin.name == "Founder One"
    assert admin.disabled is False
    assert admin.totp_secret_enc

    # Password is hashed, never stored plaintext.
    assert admin.password_hash
    assert not admin.password_hash.startswith("founder")

    # The temp password is printed and actually validates against the hash.
    lines = [line.strip() for line in output.splitlines() if line.strip()]
    label_idx = next(i for i, line in enumerate(lines) if "Temporary password" in line)
    temp_password = lines[label_idx + 1]
    assert check_password(temp_password, admin.password_hash)

    # The otpauth URI is printed and decodes against the stored secret.
    assert "otpauth://totp/" in output
    secret = decrypt(admin.totp_secret_enc)
    assert pyotp.TOTP(secret).provisioning_uri(name=_EMAIL, issuer_name="Khatir Admin") in output


def test_command_writes_audit_entry() -> None:
    _run(email=_EMAIL)
    admin = AdminUser.objects.get(email=_EMAIL)
    entry = AdminAuditEntry.objects.get(action="admin_user.create_super_admin")
    assert entry.entity_type == "admin_portal.adminuser"
    assert entry.entity_id == str(admin.pk)
    assert entry.after_json == {"email": _EMAIL, "role": AdminRole.SUPER.value}


def test_idempotent() -> None:
    _run(email=_EMAIL)
    original = AdminUser.objects.get(email=_EMAIL)

    output = _run(email=_EMAIL)

    assert AdminUser.objects.filter(email=_EMAIL).count() == 1
    refreshed = AdminUser.objects.get(email=_EMAIL)
    # Password/TOTP unchanged and not reprinted on the second run.
    assert refreshed.password_hash == original.password_hash
    assert refreshed.totp_secret_enc == original.totp_secret_enc
    assert "already exists" in output
    assert "otpauth://" not in output


def test_email_normalised_for_idempotency() -> None:
    _run(email=_EMAIL)
    output = _run(email=_EMAIL.upper())
    assert AdminUser.objects.filter(email=_EMAIL).count() == 1
    assert "already exists" in output


def test_dry_run_creates_nothing() -> None:
    output = _run(email=_EMAIL, dry_run=True)
    assert not AdminUser.objects.filter(email=_EMAIL).exists()
    assert not AdminAuditEntry.objects.exists()
    assert "dry-run" in output
    assert "otpauth://" not in output
