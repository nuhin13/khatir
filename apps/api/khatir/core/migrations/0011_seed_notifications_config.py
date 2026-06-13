"""Seed the notifications per-message cost ``SystemConfig`` keys (EPIC-15.T-009).

The admin notification composer shows a cost preview before a broadcast is sent.
The per-channel unit costs are Layer-3 config so ops can re-price without a
redeploy (``03_env_and_config.md`` §4):

* ``whatsapp_cost_per_message`` (money / Decimal)
* ``sms_cost_per_message`` (money / Decimal)
* ``email_cost_per_message`` (money / Decimal)

Values are stored as ``money`` so ``get_config`` returns a :class:`~decimal.Decimal`.
Idempotent (``update_or_create``) and reversible (reverse removes exactly the
keys it added).
"""

from django.db import migrations

NOTIFICATIONS_CONFIG = [
    {
        "key": "whatsapp_cost_per_message",
        "value": "0.50",
        "type": "money",
        "description": "Cost per WhatsApp message, used for composer cost preview.",
    },
    {
        "key": "sms_cost_per_message",
        "value": "0.30",
        "type": "money",
        "description": "Cost per SMS message, used for composer cost preview.",
    },
    {
        "key": "email_cost_per_message",
        "value": "0.00",
        "type": "money",
        "description": "Cost per email message, used for composer cost preview.",
    },
]

OWNED_KEYS = [row["key"] for row in NOTIFICATIONS_CONFIG]


def seed_notifications_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    for row in NOTIFICATIONS_CONFIG:
        SystemConfig.objects.update_or_create(
            key=row["key"],
            defaults={
                "value": row["value"],
                "type": row["type"],
                "description": row["description"],
            },
        )


def unseed_notifications_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    SystemConfig.objects.filter(key__in=OWNED_KEYS).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0010_seed_ai_config"),
    ]

    operations = [
        migrations.RunPython(seed_notifications_config, unseed_notifications_config),
    ]
