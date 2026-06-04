"""Seed the admin-tunable ``expense_categories`` + ``maintenance_categories``
``SystemConfig`` keys (EPIC-08.T-006).

Defaults mirror the :class:`khatir.maintenance.enums.ExpenseCategory` and
:class:`khatir.maintenance.enums.MaintenanceCategory` enums so the maintenance /
expense forms read an admin-extensible list rather than a hardcoded one. Each
value is a JSON-encoded array of wire values stored as ``text``
(``SystemConfigType`` has no JSON variant). Surfaced via ``/config/public``.
Idempotent (``update_or_create``) and reversible (reverse removes exactly these
keys).

Mirror of the enums — migrations must not import app code so they stay frozen
against future enum changes.
"""

import json

from django.db import migrations

MAINTENANCE_CATEGORIES = [
    "plumbing",
    "electrical",
    "paint",
    "structural",
    "appliance",
    "utility",
    "other",
]

EXPENSE_CATEGORIES = [
    "plumbing",
    "paint",
    "electrical",
    "structural",
    "appliance",
    "utility",
    "other",
]

MAINTENANCE_CATEGORIES_KEY = "maintenance_categories"
EXPENSE_CATEGORIES_KEY = "expense_categories"


def seed_category_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    SystemConfig.objects.update_or_create(
        key=MAINTENANCE_CATEGORIES_KEY,
        defaults={
            "value": json.dumps(MAINTENANCE_CATEGORIES),
            "type": "text",
            "description": "Selectable categories for maintenance requests.",
        },
    )
    SystemConfig.objects.update_or_create(
        key=EXPENSE_CATEGORIES_KEY,
        defaults={
            "value": json.dumps(EXPENSE_CATEGORIES),
            "type": "text",
            "description": "Selectable categories for expenses.",
        },
    )


def unseed_category_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    SystemConfig.objects.filter(
        key__in=[MAINTENANCE_CATEGORIES_KEY, EXPENSE_CATEGORIES_KEY]
    ).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0005_seed_free_tier_config"),
    ]

    operations = [
        migrations.RunPython(seed_category_config, unseed_category_config),
    ]
