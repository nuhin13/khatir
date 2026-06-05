"""Seed the AI-lease ``SystemConfig`` keys (EPIC-18.T-005).

The AI lease-document feature exposes three Layer-3 config knobs so ops can tune
them from the admin portal without a redeploy (``03_env_and_config.md`` §4):

* ``lease_template_version`` (text) — version tag of the active clause scaffold.
* ``lease_disclaimer_text_en`` (text) — English "not legal advice" disclaimer.
* ``lease_disclaimer_text_bn`` (text) — Bangla "not legal advice" disclaimer.

``SystemConfig`` has no JSON type (``int``/``money``/``text``/``bool`` only), so
the bilingual disclaimer is seeded as two ``text`` rows. The mandatory disclaimer
clause is always injected by the lease scaffold regardless of these rows (see
``leasedocs/scaffold.py``); these keys let ops adjust the public-facing wording.

Idempotent (``update_or_create`` keyed on the unique ``key``) and reversible
(reverse removes exactly the keys it added). Migrations never import app code, so
the values stay frozen against future model/enum changes.
"""

from django.db import migrations

LEASE_CONFIG = [
    {
        "key": "lease_template_version",
        "value": "1.0",
        "type": "text",
        "description": "Version tag of the active AI-lease clause scaffold.",
    },
    {
        "key": "lease_disclaimer_text_en",
        "value": (
            "This is an AI-generated draft, not legal advice. Consult a lawyer."
        ),
        "type": "text",
        "description": "English 'not legal advice' disclaimer for AI-lease documents.",
    },
    {
        "key": "lease_disclaimer_text_bn",
        "value": (
            "এটি একটি এআই-জেনারেটেড খসড়া, কোনো আইনি পরামর্শ নয়। "
            "একজন আইনজীবীর পরামর্শ নিন।"
        ),
        "type": "text",
        "description": "Bangla 'not legal advice' disclaimer for AI-lease documents.",
    },
]

OWNED_KEYS = [row["key"] for row in LEASE_CONFIG]


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
    SystemConfig.objects.filter(key__in=OWNED_KEYS).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0012_seed_compliance_config"),
    ]

    operations = [
        migrations.RunPython(seed_lease_config, unseed_lease_config),
    ]
