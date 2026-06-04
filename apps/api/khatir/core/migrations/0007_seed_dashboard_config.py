"""Seed the dashboard ``SystemConfig`` key (EPIC-09.T-003).

The default look-back window for the landlord dashboard's income/expense
trend lives in ``SystemConfig`` so it can be tuned from the admin portal
without a redeploy (used by EPIC-09.T-002). Idempotent
(``update_or_create``) and reversible (reverse removes exactly this key).
"""

from django.db import migrations

DASHBOARD_CONFIG = [
    {
        "key": "dashboard_months_default",
        "value": "6",
        "type": "int",
        "description": (
            "Default number of months of income/expense history shown on the "
            "landlord dashboard trend chart."
        ),
    },
]

SEEDED_KEYS = [row["key"] for row in DASHBOARD_CONFIG]


def seed_dashboard_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    for row in DASHBOARD_CONFIG:
        SystemConfig.objects.update_or_create(
            key=row["key"],
            defaults={
                "value": row["value"],
                "type": row["type"],
                "description": row["description"],
            },
        )


def unseed_dashboard_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    SystemConfig.objects.filter(key__in=SEEDED_KEYS).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0006_seed_category_config"),
    ]

    operations = [
        migrations.RunPython(seed_dashboard_config, unseed_dashboard_config),
    ]
