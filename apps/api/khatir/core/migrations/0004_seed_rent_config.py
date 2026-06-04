"""Seed admin-tunable rent-collection ``SystemConfig`` keys (EPIC-07.T-009).

Inserts the rent-collection tunables: the reminder cadence, the payment-link
token TTL, and the accepted payment-proof types. ``rent_reminder_cadence_hours``
and ``payment_proof_types`` are JSON-encoded arrays stored as ``text``
(``SystemConfigType`` has no JSON variant); ``rent_link_token_ttl_hours`` is an
``int``. ``payment_proof_types`` may surface via ``/config/public`` for the
tenant rent web page. Idempotent (``update_or_create``) and reversible (reverse
removes exactly these keys).
"""

import json

from django.db import migrations

RENT_CONFIG = [
    {
        "key": "rent_reminder_cadence_hours",
        "value": json.dumps([24, 48]),
        "type": "text",
        "description": "Hours after the due date at which rent reminders are sent.",
    },
    {
        "key": "rent_link_token_ttl_hours",
        "value": "168",
        "type": "int",
        "description": "Hours a rent payment-link token stays valid (7 days).",
    },
    {
        "key": "payment_proof_types",
        "value": json.dumps(["bkash_txn", "nagad_txn", "screenshot", "note"]),
        "type": "text",
        "description": "Accepted proof-of-payment types for rent collection.",
    },
]

SEEDED_KEYS = [row["key"] for row in RENT_CONFIG]


def seed_rent_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    for row in RENT_CONFIG:
        SystemConfig.objects.update_or_create(
            key=row["key"],
            defaults={
                "value": row["value"],
                "type": row["type"],
                "description": row["description"],
            },
        )


def unseed_rent_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    SystemConfig.objects.filter(key__in=SEEDED_KEYS).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0003_seed_area_options"),
    ]

    operations = [
        migrations.RunPython(seed_rent_config, unseed_rent_config),
    ]
