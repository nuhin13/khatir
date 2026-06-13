"""Seed the gov-export ``gov_export_format_version`` ``SystemConfig`` key (EPIC-26.T-005).

The government-submission package builder (EPIC-26.T-002) tags every structured
file and ``GovExport`` ledger row with the active *format version*. Ops may bump
this without a redeploy when the official template changes
(``03_env_and_config.md`` §4), so it lives in ``SystemConfig`` and is read through
the cached ``core.config.get_config()`` accessor.

The seeded value matches ``govexport.builder.DEFAULT_FORMAT_VERSION`` (the
fallback used until this row exists). Stored as ``text`` so ``get_config`` returns
the version string verbatim. Idempotent (``update_or_create``) and reversible
(reverse removes exactly the key it added).
"""

from django.db import migrations

GOV_EXPORT_CONFIG = [
    {
        "key": "gov_export_format_version",
        "value": "2026.1",
        "type": "text",
        "description": "Active gov-export structured-file/template format version.",
    },
]

OWNED_KEYS = [row["key"] for row in GOV_EXPORT_CONFIG]


def seed_gov_export_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    for row in GOV_EXPORT_CONFIG:
        SystemConfig.objects.update_or_create(
            key=row["key"],
            defaults={
                "value": row["value"],
                "type": row["type"],
                "description": row["description"],
            },
        )


def unseed_gov_export_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    SystemConfig.objects.filter(key__in=OWNED_KEYS).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0012_seed_compliance_config"),
    ]

    operations = [
        migrations.RunPython(seed_gov_export_config, unseed_gov_export_config),
    ]
