"""Seed lease scheduling ``SystemConfig`` keys (EPIC-06.T-006).

Inserts the admin-tunable due-day and overdue grace defaults used by rent
scheduling (T-002) and overdue detection (T-005). Idempotent (uses
``update_or_create``) and reversible (reverse removes exactly these keys).
"""

from django.db import migrations

LEASE_CONFIG = [
    {
        "key": "default_due_day",
        "value": "5",
        "type": "int",
        "description": "Default day of month a rent installment falls due.",
    },
    {
        "key": "rent_overdue_grace_days",
        "value": "3",
        "type": "int",
        "description": "Days after the due date before rent is marked overdue.",
    },
]

SEEDED_KEYS = [row["key"] for row in LEASE_CONFIG]


def seed_lease_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    for row in LEASE_CONFIG:
        SystemConfig.objects.update_or_create(
            key=row["key"],
            defaults={
                "value": row["value"],
                "type": row["type"],
                "description": row["description"],
            },
        )


def unseed_lease_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    SystemConfig.objects.filter(key__in=SEEDED_KEYS).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("leases", "0001_initial"),
        ("core", "0001_initial"),
    ]

    operations = [
        migrations.RunPython(seed_lease_config, unseed_lease_config),
    ]
