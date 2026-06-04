"""Seed the AI-gateway ``SystemConfig`` keys (EPIC-14.T-010).

The AI provider gateway is reached through a small set of Layer-3 config knobs
so they can be tuned from the admin portal without a redeploy:

* ``ai_gateway_url`` (text) — base URL of the AI provider gateway.
* ``ai_gateway_secret`` (text) — shared secret between Django and the gateway.
  Seeded empty: the real value is supplied out-of-band (admin portal / env) and
  must never be written into a migration, fixture, or log.
* ``ai_provider_cache_ttl_seconds`` (int) — TTL for the gateway response cache.

Idempotent (``update_or_create`` only touches non-secret metadata for the
secret key, never overwriting an operator-set value) and reversible (reverse
removes exactly the keys it added).
"""

from django.db import migrations

# Non-secret rows are fully owned by this migration.
AI_CONFIG = [
    {
        "key": "ai_gateway_url",
        "value": "",
        "type": "text",
        "description": "Base URL of the AI provider gateway.",
    },
    {
        "key": "ai_provider_cache_ttl_seconds",
        "value": "300",
        "type": "int",
        "description": "TTL (seconds) for cached AI gateway responses.",
    },
]

# The secret key is seeded as an empty placeholder. We only ever create it if
# absent and never overwrite an existing value, so an operator-set secret is
# preserved across re-runs and the secret itself is never embedded here.
SECRET_KEY = "ai_gateway_secret"
SECRET_DESCRIPTION = (
    "Shared secret between Django and the AI gateway. Set out-of-band; "
    "treat as sensitive and keep out of logs."
)

OWNED_KEYS = [row["key"] for row in AI_CONFIG] + [SECRET_KEY]


def seed_ai_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    for row in AI_CONFIG:
        SystemConfig.objects.update_or_create(
            key=row["key"],
            defaults={
                "value": row["value"],
                "type": row["type"],
                "description": row["description"],
            },
        )
    SystemConfig.objects.get_or_create(
        key=SECRET_KEY,
        defaults={
            "value": "",
            "type": "text",
            "description": SECRET_DESCRIPTION,
        },
    )


def unseed_ai_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    SystemConfig.objects.filter(key__in=OWNED_KEYS).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0009_seed_admin_config"),
    ]

    operations = [
        migrations.RunPython(seed_ai_config, unseed_ai_config),
    ]
