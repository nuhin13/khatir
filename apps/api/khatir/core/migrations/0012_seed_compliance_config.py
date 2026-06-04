"""Seed the compliance SLA ``SystemConfig`` keys (EPIC-16.T-005).

Data-subject request handling has two tunable deadlines that ops may adjust
without a redeploy (``03_env_and_config.md`` §4):

* ``data_request_sla_days`` (int) — days to fulfil a data-subject request.
* ``data_delete_grace_days`` (int) — grace period before an approved delete
  request is irreversibly executed.

Values are stored as ``int`` so ``get_config`` returns a Python ``int``.
Idempotent (``update_or_create``) and reversible (reverse removes exactly the
keys it added).
"""

from django.db import migrations

COMPLIANCE_CONFIG = [
    {
        "key": "data_request_sla_days",
        "value": "30",
        "type": "int",
        "description": "Days to fulfil a data-subject request before it breaches SLA.",
    },
    {
        "key": "data_delete_grace_days",
        "value": "7",
        "type": "int",
        "description": "Grace period (days) before an approved delete request is executed.",
    },
]

OWNED_KEYS = [row["key"] for row in COMPLIANCE_CONFIG]


def seed_compliance_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    for row in COMPLIANCE_CONFIG:
        SystemConfig.objects.update_or_create(
            key=row["key"],
            defaults={
                "value": row["value"],
                "type": row["type"],
                "description": row["description"],
            },
        )


def unseed_compliance_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    SystemConfig.objects.filter(key__in=OWNED_KEYS).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0011_seed_notifications_config"),
    ]

    operations = [
        migrations.RunPython(seed_compliance_config, unseed_compliance_config),
    ]
