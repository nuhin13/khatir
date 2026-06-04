"""Seed the admin-session ``SystemConfig`` keys (EPIC-11.T-006).

Admin-portal session knobs live in ``SystemConfig`` (Layer-3 config) so they can
be tuned from the portal without a redeploy and are consumed by the admin auth
guard (T-003):

* ``admin_session_timeout_minutes`` (int) — idle minutes before an admin session
  is invalidated.
* ``admin_mfa_required`` (bool) — whether MFA is mandatory for admin sign-in.

Idempotent (``update_or_create``) and reversible (reverse removes exactly the
keys it added).
"""

from django.db import migrations

ADMIN_CONFIG = [
    {
        "key": "admin_session_timeout_minutes",
        "value": "60",
        "type": "int",
        "description": (
            "Idle minutes before an admin-portal session is invalidated."
        ),
    },
    {
        "key": "admin_mfa_required",
        "value": "true",
        "type": "bool",
        "description": "Whether MFA is mandatory for admin-portal sign-in.",
    },
]

OWNED_KEYS = [row["key"] for row in ADMIN_CONFIG]


def seed_admin_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    for row in ADMIN_CONFIG:
        SystemConfig.objects.update_or_create(
            key=row["key"],
            defaults={
                "value": row["value"],
                "type": row["type"],
                "description": row["description"],
            },
        )


def unseed_admin_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    SystemConfig.objects.filter(key__in=OWNED_KEYS).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0008_seed_pricing_config"),
    ]

    operations = [
        migrations.RunPython(seed_admin_config, unseed_admin_config),
    ]
