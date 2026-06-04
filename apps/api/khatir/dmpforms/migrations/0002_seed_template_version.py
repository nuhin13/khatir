"""Seed the ``dmp_template_version`` SystemConfig key (EPIC-05.T-006).

The DMP form template version is a Layer-3 config value (``03_env_and_config.md``)
so layout updates can roll out without a redeploy: PDF generation reads it and
each ``DMPFormRecord`` stores the version it was generated with. Idempotent
(uses ``update_or_create``) and reversible (reverse removes exactly this key).
"""

from django.db import migrations

TEMPLATE_VERSION_CONFIG = {
    "key": "dmp_template_version",
    "value": "2026.1",
    "type": "text",
    "description": (
        "Current DMP form template version (e.g. '2026.1'). PDF generation "
        "reads this; each generated record stores the version it used. Bump "
        "when the official form changes — old records keep their version."
    ),
}


def seed_template_version(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    SystemConfig.objects.update_or_create(
        key=TEMPLATE_VERSION_CONFIG["key"],
        defaults={
            "value": TEMPLATE_VERSION_CONFIG["value"],
            "type": TEMPLATE_VERSION_CONFIG["type"],
            "description": TEMPLATE_VERSION_CONFIG["description"],
        },
    )


def unseed_template_version(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    SystemConfig.objects.filter(key=TEMPLATE_VERSION_CONFIG["key"]).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("dmpforms", "0001_initial"),
        ("core", "0001_initial"),
    ]

    operations = [
        migrations.RunPython(seed_template_version, unseed_template_version),
    ]
