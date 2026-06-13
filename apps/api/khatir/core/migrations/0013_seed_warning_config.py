"""Seed the private-warning ``SystemConfig`` keys (EPIC-20.T-004).

Private landlord-to-tenant warnings need two admin-tunable pieces of Layer-3
config (``03_env_and_config.md`` §4):

* ``warning_types`` — the selectable reason categories shown in the warning
  composer. Stored as a JSON-encoded array under ``text`` because
  ``SystemConfigType`` has no JSON variant (same approach as ``area_options``).
* ``warning_disclaimer_text_en`` / ``warning_disclaimer_text_bn`` — the
  mandatory bilingual legal disclaimer printed on every warning notice
  (``T-003`` notice; task §15). This is a *private* notice between landlord and
  tenant, not a legal judgment.

Values mirror ``khatir.warnings.enums.WarningType`` and
``khatir.warnings.notice.DISCLAIMER`` but are duplicated here because migrations
must stay frozen against future app-code changes. Idempotent
(``update_or_create``) and reversible (reverse removes exactly the keys added).
"""

import json

from django.db import migrations

# Mirror of the task §15 warning reason categories. Duplicated (not imported)
# so the migration stays frozen if the app enum changes later.
WARNING_TYPES = [
    "late_rent",
    "lease_violation",
    "noise",
    "property_damage",
    "other",
]

WARNING_DISCLAIMER_EN = (
    "Disclaimer: This is a private notice between landlord and tenant, "
    "not a legal judgment."
)
WARNING_DISCLAIMER_BN = (
    "দাবিত্যাগ: এটি বাড়িওয়ালা ও ভাড়াটিয়ার মধ্যে একটি ব্যক্তিগত নোটিশ, "
    "কোনো আইনি রায় নয়।"
)

WARNING_CONFIG = [
    {
        "key": "warning_types",
        "value": json.dumps(WARNING_TYPES),
        "type": "text",
        "description": "Selectable warning reason categories for the warning composer.",
    },
    {
        "key": "warning_disclaimer_text_en",
        "value": WARNING_DISCLAIMER_EN,
        "type": "text",
        "description": "Mandatory legal disclaimer (English) printed on every warning notice.",
    },
    {
        "key": "warning_disclaimer_text_bn",
        "value": WARNING_DISCLAIMER_BN,
        "type": "text",
        "description": "Mandatory legal disclaimer (Bangla) printed on every warning notice.",
    },
]

OWNED_KEYS = [row["key"] for row in WARNING_CONFIG]


def seed_warning_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    for row in WARNING_CONFIG:
        SystemConfig.objects.update_or_create(
            key=row["key"],
            defaults={
                "value": row["value"],
                "type": row["type"],
                "description": row["description"],
            },
        )


def unseed_warning_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    SystemConfig.objects.filter(key__in=OWNED_KEYS).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0012_seed_compliance_config"),
    ]

    operations = [
        migrations.RunPython(seed_warning_config, unseed_warning_config),
    ]
