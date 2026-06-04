"""Seed the pricing ``SystemConfig`` keys (EPIC-10.T-006).

Pricing knobs live in ``SystemConfig`` (Layer-3 config) so an admin can tune them
from the portal without a redeploy (``06_database_schema.md`` §"Free tier"):

* ``free_tier_tenant_limit`` (int) — tenants a landlord may manage before an
  upgrade is required. Re-asserted idempotently here (also seeded by 0005).
* ``nid_verification_tiers`` (JSON list, stored as ``text`` — ``SystemConfigType``
  has no JSON variant) — the selectable NID-verification purchase tiers.

Idempotent (``update_or_create``) and reversible (reverse removes exactly the
key it added — ``free_tier_tenant_limit`` is owned by 0005 and left intact).
"""

import json

from django.db import migrations

NID_VERIFICATION_TIERS = [
    "bundle_10",
    "bundle_20",
    "bundle_50",
    "unlimited",
]

PRICING_CONFIG = [
    {
        "key": "free_tier_tenant_limit",
        "value": "2",
        "type": "int",
        "description": (
            "Number of tenants a landlord may manage on the free tier "
            "before an upgrade is required."
        ),
    },
    {
        "key": "nid_verification_tiers",
        "value": json.dumps(NID_VERIFICATION_TIERS),
        "type": "text",
        "description": "Selectable NID-verification purchase tiers.",
    },
]

# Only this key is owned by this migration; ``free_tier_tenant_limit`` is owned
# by 0005 and must survive a reverse of this migration.
OWNED_KEYS = ["nid_verification_tiers"]


def seed_pricing_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    for row in PRICING_CONFIG:
        SystemConfig.objects.update_or_create(
            key=row["key"],
            defaults={
                "value": row["value"],
                "type": row["type"],
                "description": row["description"],
            },
        )


def unseed_pricing_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    SystemConfig.objects.filter(key__in=OWNED_KEYS).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0007_seed_dashboard_config"),
    ]

    operations = [
        migrations.RunPython(seed_pricing_config, unseed_pricing_config),
    ]
