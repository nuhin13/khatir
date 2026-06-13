"""``create_super_admin`` — seed the first super-admin account (T-012).

A one-time, **idempotent** setup command so the admin portal is usable right
after deploy. It creates a single :class:`~khatir.admin_portal.models.AdminUser`
with the ``super`` role, a freshly generated TOTP secret (encrypted at rest via
``core.encryption``), and a random temporary password.

The temporary password and the ``otpauth://`` provisioning URI are printed to
stdout **exactly once** — there is no way to recover them afterwards. The admin
scans the URI into Google Authenticator / Authy and changes the password on
first login.

Idempotency: if an account with the given email already exists the command
makes no changes and exits successfully (the password/TOTP are NOT reprinted,
since they are not recoverable).

Usage::

    python manage.py create_super_admin --email admin@khatir.io --name "Jane Ops"
    python manage.py create_super_admin --email admin@khatir.io --dry-run
"""

from __future__ import annotations

import secrets
from typing import Any

import pyotp
from django.contrib.auth.hashers import make_password
from django.core.management.base import BaseCommand, CommandParser

from khatir.admin_portal.audit import admin_audit
from khatir.admin_portal.models import AdminUser
from khatir.core.encryption import encrypt
from khatir.core.enums import AdminRole

_TOTP_ISSUER = "Khatir Admin"
# Length of the generated temporary password (URL-safe token, no ambiguous I/O).
_TEMP_PASSWORD_BYTES = 18


class Command(BaseCommand):
    help = "Create the first super-admin account (idempotent); prints a temp password + TOTP URI."

    def add_arguments(self, parser: CommandParser) -> None:
        parser.add_argument(
            "--email",
            required=True,
            help="Login email for the super-admin (unique across admin accounts).",
        )
        parser.add_argument(
            "--name",
            default="Super Admin",
            help="Display name for the account.",
        )
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Report what would happen without writing anything.",
        )

    def handle(self, *args: Any, **options: Any) -> None:
        email = str(options["email"]).strip().lower()
        name = str(options["name"]).strip()
        dry_run = bool(options["dry_run"])

        if AdminUser.objects.filter(email=email).exists():
            # Idempotent: nothing to do, and we never reprint secrets.
            self.stdout.write(
                self.style.WARNING(
                    f"Super-admin '{email}' already exists — no changes made."
                )
            )
            return

        if dry_run:
            self.stdout.write(
                self.style.NOTICE(
                    f"[dry-run] Would create super-admin '{email}' (name='{name}'). "
                    "No password or TOTP secret generated."
                )
            )
            return

        temp_password = secrets.token_urlsafe(_TEMP_PASSWORD_BYTES)
        totp_secret = pyotp.random_base32()
        provisioning_uri = pyotp.TOTP(totp_secret).provisioning_uri(
            name=email, issuer_name=_TOTP_ISSUER
        )

        admin_user = AdminUser.objects.create(
            email=email,
            name=name,
            password_hash=make_password(temp_password),
            totp_secret_enc=encrypt(totp_secret),
            role=AdminRole.SUPER,
            scope={},
            disabled=False,
        )

        admin_audit(
            admin_user=None,
            action="admin_user.create_super_admin",
            entity=admin_user,
            after={"email": email, "role": AdminRole.SUPER.value},
            reason="Initial super-admin seeded via create_super_admin command.",
        )

        # Print secrets ONCE. Never log them after this point (task §15).
        self.stdout.write(self.style.SUCCESS(f"Created super-admin '{email}'."))
        self.stdout.write("")
        self.stdout.write(self.style.WARNING("Temporary password (shown once):"))
        self.stdout.write(f"    {temp_password}")
        self.stdout.write("")
        self.stdout.write(
            self.style.WARNING("TOTP setup — scan this into Google Authenticator / Authy:")
        )
        self.stdout.write(f"    {provisioning_uri}")
        self.stdout.write("")
        self.stdout.write(
            self.style.NOTICE(
                "Store these now — they cannot be recovered. "
                "Change the password on first login."
            )
        )
