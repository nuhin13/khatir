"""Seed the history-flags ``SystemConfig`` keys (EPIC-24.T-005).

The tenant-controlled, consent-per-share history feature has two tunable
settings ops may adjust without a redeploy (``03_env_and_config.md`` §4):

* ``history_share_default_expiry_days`` (int) — default lifetime, in days, of a
  history share grant when the tenant does not pick an explicit expiry.
* ``history_share_disclaimer_text`` (text) — the factual-only / consent
  disclaimer surfaced to both tenant and recipient at share time.

The default-expiry value is stored as ``int`` so ``get_config`` returns a
Python ``int``; the disclaimer is ``text``. Idempotent (``update_or_create``)
and reversible (reverse removes exactly the keys it added).
"""

from django.db import migrations

HISTORY_FLAGS_CONFIG = [
    {
        "key": "history_share_default_expiry_days",
        "value": "30",
        "type": "int",
        "description": (
            "Default lifetime (days) of a tenant-initiated history share when "
            "no explicit expiry is chosen."
        ),
    },
    {
        "key": "history_share_disclaimer_text",
        "value": (
            "This record is shared by the tenant with their explicit consent "
            "and shows only factual tenancy data (on-time payment count, lease "
            "completion). It contains no subjective ratings or flags. The "
            "tenant can revoke access at any time."
        ),
        "type": "text",
        "description": (
            "Factual-only / consent disclaimer shown to the tenant and the "
            "recipient landlord at share time."
        ),
    },
]

OWNED_KEYS = [row["key"] for row in HISTORY_FLAGS_CONFIG]


def seed_history_flags_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    for row in HISTORY_FLAGS_CONFIG:
        SystemConfig.objects.update_or_create(
            key=row["key"],
            defaults={
                "value": row["value"],
                "type": row["type"],
                "description": row["description"],
            },
        )


def unseed_history_flags_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    SystemConfig.objects.filter(key__in=OWNED_KEYS).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0012_seed_compliance_config"),
    ]

    operations = [
        migrations.RunPython(seed_history_flags_config, unseed_history_flags_config),
    ]
