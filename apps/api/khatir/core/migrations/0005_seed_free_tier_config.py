"""Seed the free-tier tenant limit ``SystemConfig`` key (EPIC-04.T-008).

The "first 2 tenants free" limit lives in ``SystemConfig``, not in code, so an
admin can raise it (2 → 3) from the portal without a redeploy
(``06_database_schema.md`` §"Free tier"). Idempotent (``update_or_create``) and
reversible (reverse removes exactly this key).
"""

from django.db import migrations

FREE_TIER_CONFIG = [
    {
        "key": "free_tier_tenant_limit",
        "value": "2",
        "type": "int",
        "description": (
            "Number of tenants a landlord may manage on the free tier "
            "before an upgrade is required."
        ),
    },
]

SEEDED_KEYS = [row["key"] for row in FREE_TIER_CONFIG]


def seed_free_tier_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    for row in FREE_TIER_CONFIG:
        SystemConfig.objects.update_or_create(
            key=row["key"],
            defaults={
                "value": row["value"],
                "type": row["type"],
                "description": row["description"],
            },
        )


def unseed_free_tier_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    SystemConfig.objects.filter(key__in=SEEDED_KEYS).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0004_seed_rent_config"),
    ]

    operations = [
        migrations.RunPython(seed_free_tier_config, unseed_free_tier_config),
    ]
