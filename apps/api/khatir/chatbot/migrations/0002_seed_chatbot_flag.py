"""Seed the ``chatbot_enabled`` feature flag + chatbot config (EPIC-23.T-005).

So the in-app assistant ships **on** from day one (the epic declares
``chatbot_enabled`` *default on*, kill-switchable) and carries its
cost-control config alongside the flag.

**Convention (EPIC-13.T-004):** ``enabled=True`` means the feature IS ON;
an admin flips the flag to ``enabled=False`` to kill the chatbot in an
emergency. ``chatbot_enabled`` is therefore seeded ``enabled=True``.

The ``chatbot_rate_limit_per_hour`` config rides in the flag's ``value_json``
payload (the model's intended home for thresholds/config — see
``FeatureFlag.value_json``), so ops can tune the per-user message cap from the
admin without a code change. The default mirrors the DRF ``chat_message``
throttle rate (``60/hour``) shipped by EPIC-23.T-002.

Idempotent (``update_or_create`` keyed on the unique ``key``) and reversible
(reverse removes exactly this key). Migrations never import app code, so the
flag definition stays frozen against future model/enum changes; ``scope`` uses
the literal wire value ``"global"`` rather than the ``FlagScope`` enum.

**Test isolation:** mirrors ``featureflags.0002_seed_flags`` — the auto-run is a
no-op under the test settings module (so it never pollutes featureflags/chatbot
flag tests that assert against an empty table). ``test_seed_chatbot_flag``
invokes ``seed_chatbot_flag`` directly with ``schema_editor=None`` to verify it.
Dev/prod always run the seed.
"""

from django.conf import settings
from django.db import migrations

#: Flag gating the in-app chatbot (EPIC-23 epic §"Feature flags", default on).
CHATBOT_FLAG_KEY = "chatbot_enabled"
CHATBOT_FLAG_DESCRIPTION = "In-app support/guidance chatbot (EPIC-23). Default on; kill-switchable."

#: Per-user message cap (matches the DRF ``chat_message`` throttle, 60/hour).
DEFAULT_RATE_LIMIT_PER_HOUR = 60
CHATBOT_VALUE_JSON = {"chatbot_rate_limit_per_hour": DEFAULT_RATE_LIMIT_PER_HOUR}


def _under_test() -> bool:
    """True when running against the test settings module (suite isolation)."""
    return settings.SETTINGS_MODULE == "config.settings.test"


def seed_chatbot_flag(apps, schema_editor):
    if schema_editor is not None and _under_test():
        # Auto-run during the test DB build is skipped (see module docstring);
        # ``test_seed_chatbot_flag`` calls this with ``schema_editor=None``.
        return
    FeatureFlag = apps.get_model("featureflags", "FeatureFlag")
    FeatureFlag.objects.update_or_create(
        key=CHATBOT_FLAG_KEY,
        defaults={
            "description": CHATBOT_FLAG_DESCRIPTION,
            "scope": "global",
            "enabled": True,
            "value_json": CHATBOT_VALUE_JSON,
        },
    )


def unseed_chatbot_flag(apps, schema_editor):
    FeatureFlag = apps.get_model("featureflags", "FeatureFlag")
    FeatureFlag.objects.filter(key=CHATBOT_FLAG_KEY).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("chatbot", "0001_initial"),
        ("featureflags", "0002_seed_flags"),
    ]

    operations = [
        migrations.RunPython(seed_chatbot_flag, unseed_chatbot_flag),
    ]
