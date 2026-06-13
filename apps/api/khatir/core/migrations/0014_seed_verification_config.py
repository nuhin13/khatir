"""Seed the EC NID-verification ``SystemConfig`` keys (EPIC-17.T-005).

The NID/EC verification feature needs three admin-tunable Layer-3 config keys
(``03_env_and_config.md`` §4). These document *which* approved Election
Commission provider is in use, *where* it lives, and the Data Processing
Agreement that legally authorises sending PII to it:

* ``ec_verification_provider`` — code identifier of the active EC provider
  (e.g. the vendor whose client lives in ``khatir.verification.providers``).
* ``ec_verification_endpoint`` — operator-visible record of the provider
  endpoint URL.
* ``ec_verification_dpa_reference`` — the DPA reference that legally authorises
  submitting PII to the vendor. **Required before live use** (PDPA): the
  provider refuses to call the vendor without it (EPIC-17.T-002), so this key
  is seeded empty and an admin must fill it in before going live.

These are distinct from the secret runtime credentials (``EC_VERIFICATION_*``
in settings/env): those carry the API key and operational endpoint, while these
``SystemConfig`` rows are the admin-editable, audited record of the provider
choice + DPA reference. All three are seeded ``text`` and intentionally empty —
they MUST be populated by an admin before the feature can go live.

Idempotent (``update_or_create`` keyed on ``key``, and the reverse only deletes
keys that are still empty so it never clobbers an admin-entered value) and
reversible.
"""

from django.db import migrations

VERIFICATION_CONFIG = [
    {
        "key": "ec_verification_provider",
        "value": "",
        "type": "text",
        "description": "Code identifier of the active EC NID-verification provider.",
    },
    {
        "key": "ec_verification_endpoint",
        "value": "",
        "type": "text",
        "description": "Endpoint URL of the active EC NID-verification provider.",
    },
    {
        "key": "ec_verification_dpa_reference",
        "value": "",
        "type": "text",
        "description": (
            "Data Processing Agreement reference authorising PII submission to "
            "the EC vendor. REQUIRED before live use (PDPA)."
        ),
    },
]

OWNED_KEYS = [row["key"] for row in VERIFICATION_CONFIG]


def seed_verification_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    for row in VERIFICATION_CONFIG:
        # Seed only when absent so a re-run never overwrites an admin-entered
        # DPA reference / provider value with the empty default.
        SystemConfig.objects.get_or_create(
            key=row["key"],
            defaults={
                "value": row["value"],
                "type": row["type"],
                "description": row["description"],
            },
        )


def unseed_verification_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    # Only remove rows still at their empty seed value — never delete config an
    # admin has since populated.
    SystemConfig.objects.filter(key__in=OWNED_KEYS, value="").delete()


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0013_seed_warning_config"),
    ]

    operations = [
        migrations.RunPython(seed_verification_config, unseed_verification_config),
    ]
