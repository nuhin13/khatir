"""Seed admin-tunable authentication ``SystemConfig`` keys (EPIC-01.T-001).

Inserts the OTP/auth tunables defined in ``03_env_and_config.md`` (Layer-3
config) so OTP behavior is configurable from day one. Idempotent (uses
``update_or_create``) and reversible (reverse removes exactly these keys).
"""

from django.db import migrations

AUTH_CONFIG = [
    {
        "key": "otp_length",
        "value": "6",
        "type": "int",
        "description": "Number of digits in a one-time passcode.",
    },
    {
        "key": "otp_ttl_seconds",
        "value": "300",
        "type": "int",
        "description": "Seconds a one-time passcode remains valid before expiring.",
    },
    {
        "key": "otp_max_attempts",
        "value": "5",
        "type": "int",
        "description": "Maximum verification attempts allowed per one-time passcode.",
    },
    {
        "key": "otp_resend_cooldown_seconds",
        "value": "60",
        "type": "int",
        "description": "Seconds a user must wait before requesting another OTP.",
    },
    {
        "key": "auth_primary_channel",
        "value": "whatsapp",
        "type": "text",
        "description": "Primary delivery channel for authentication OTPs.",
    },
    {
        "key": "intro_slide_skip_allowed",
        "value": "true",
        "type": "bool",
        "description": "Whether users may skip the onboarding intro slides.",
    },
]

SEEDED_KEYS = [row["key"] for row in AUTH_CONFIG]


def seed_auth_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    for row in AUTH_CONFIG:
        SystemConfig.objects.update_or_create(
            key=row["key"],
            defaults={
                "value": row["value"],
                "type": row["type"],
                "description": row["description"],
            },
        )


def unseed_auth_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    SystemConfig.objects.filter(key__in=SEEDED_KEYS).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0001_initial"),
    ]

    operations = [
        migrations.RunPython(seed_auth_config, unseed_auth_config),
    ]
