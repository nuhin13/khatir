"""Seed the mutual-review ``SystemConfig`` keys (EPIC-21.T-004).

Mutual reviews between landlords and tenants are tunable Layer-3 config so ops
can adjust them without a redeploy (``03_env_and_config.md`` §4):

* ``review_rating_scale`` (int) — the upper bound of the star rating scale (5).
* ``review_disclaimer_text`` (text / JSON ``{"bn": ..., "en": ...}``) — the
  bilingual disclaimer shown before a review is submitted.

The disclaimer must make it unambiguous that reviews are **private between the
two parties and are never published** — Khatir has no public reputation system
(see EPIC-21.T-009). The JSON shape mirrors other bilingual ``text`` configs
(e.g. ``area_options``) and is returned verbatim by ``get_config``.

Idempotent (``update_or_create``) and reversible (reverse removes exactly the
keys it added).
"""

import json

from django.db import migrations

# Mirror of the bilingual disclaimer copy. Migrations must not import app code
# so they stay frozen against future changes. Both strings emphasise that the
# review stays private between the parties and is never made public.
REVIEW_DISCLAIMER_TEXT = {
    "en": (
        "This review is private and shared only between you and the other "
        "party. Khatir never publishes reviews and has no public reputation "
        "or rating system."
    ),
    "bn": (
        "এই রিভিউটি ব্যক্তিগত এবং শুধুমাত্র আপনার ও অপর পক্ষের মধ্যে শেয়ার করা "
        "হয়। খাতির কখনও রিভিউ প্রকাশ করে না এবং কোনো পাবলিক রেপুটেশন বা রেটিং "
        "ব্যবস্থা নেই।"
    ),
}

REVIEW_CONFIG = [
    {
        "key": "review_rating_scale",
        "value": "5",
        "type": "int",
        "description": "Upper bound of the mutual-review star rating scale.",
    },
    {
        "key": "review_disclaimer_text",
        "value": json.dumps(REVIEW_DISCLAIMER_TEXT, ensure_ascii=False),
        "type": "text",
        "description": (
            "Bilingual (bn/en) disclaimer stating reviews are private between "
            "the parties and never published."
        ),
    },
]

OWNED_KEYS = [row["key"] for row in REVIEW_CONFIG]


def seed_review_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    for row in REVIEW_CONFIG:
        SystemConfig.objects.update_or_create(
            key=row["key"],
            defaults={
                "value": row["value"],
                "type": row["type"],
                "description": row["description"],
            },
        )


def unseed_review_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    SystemConfig.objects.filter(key__in=OWNED_KEYS).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("core", "0012_seed_compliance_config"),
    ]

    operations = [
        migrations.RunPython(seed_review_config, unseed_review_config),
    ]
