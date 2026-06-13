"""Seed the admin-tunable ``area_options`` ``SystemConfig`` key (EPIC-03.T-006).

Makes the Dhaka area list admin-configurable instead of hardcoded. The value is
a JSON-encoded array of the :class:`khatir.core.enums.Area` enum values, stored
as ``text`` (``SystemConfigType`` has no JSON variant). Exposed via
``/config/public`` so the property wizard reads it. Idempotent
(``update_or_create``) and reversible (reverse removes exactly this key).
"""

import json

from django.db import migrations

# Mirror of ``khatir.core.enums.Area`` — migrations must not import app code
# directly so they stay frozen against future enum changes.
AREA_OPTIONS = [
    "uttara",
    "mirpur",
    "mohammadpur",
    "dhanmondi",
    "banasree",
    "gulshan",
    "banani",
    "bashundhara",
    "old_dhaka",
    "other",
]

AREA_OPTIONS_KEY = "area_options"


def seed_area_options(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    SystemConfig.objects.update_or_create(
        key=AREA_OPTIONS_KEY,
        defaults={
            "value": json.dumps(AREA_OPTIONS),
            "type": "text",
            "description": "Selectable Dhaka areas for the property wizard.",
        },
    )


def unseed_area_options(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    SystemConfig.objects.filter(key=AREA_OPTIONS_KEY).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0002_seed_auth_config"),
    ]

    operations = [
        migrations.RunPython(seed_area_options, unseed_area_options),
    ]
