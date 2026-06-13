"""Seed the 5 legally-required kill-switches + default feature flags (T-004).

So the platform ships with its emergency kill-switches and baseline feature
flags from day one.

**Kill-switch convention (see T-004 §15):** ``enabled=True`` means the feature
IS ON. Throwing the switch to ``enabled=False`` is what KILLS the feature. All
5 kill-switches are therefore seeded ``enabled=True`` (feature live) and the
admin flips them OFF in an emergency.

Default feature flags ``voice_tenant_entry`` (consumed by EPIC-04) and
``dmp_enabled`` are likewise seeded ``enabled=True``.

Idempotent (``update_or_create`` keyed on the unique ``key``) and reversible
(reverse removes exactly these 7 keys). Migrations never import app code, so the
flag definitions stay frozen against future model/enum changes; scope uses the
literal wire value ``"global"`` rather than the ``FlagScope`` enum.

**Test isolation:** the seed is a no-op under the test settings module. The
EPIC-13.T-002/T-003 flag-endpoint tests (already committed) assert against an
empty flags table and build their own rows with these very keys, so auto-seeding
would pollute every featureflags test. ``test_seed_flags`` invokes ``seed_flags``
directly to verify it instead. Dev/prod always run the seed.
"""

from django.conf import settings
from django.db import migrations

# (key, description) for the 5 kill-switches. All seeded enabled=True (feature
# live); admin sets enabled=False to kill the feature.
KILL_SWITCHES = [
    ("warnings_feature", "Private landlord warnings system."),
    ("reviews_feature", "Mutual landlord/tenant reviews."),
    ("history_flags_feature", "Tenant-initiated rental-history sharing."),
    ("free_text_feature", "User-authored free-text content."),
    (
        "master_kill_switch",
        "Global master kill-switch — OFF disables the whole platform.",
    ),
]

# (key, description) for default feature flags. All seeded enabled=True.
FEATURE_FLAGS = [
    ("voice_tenant_entry", "Voice-assisted tenant data entry (EPIC-04)."),
    ("dmp_enabled", "Digital money/payment features."),
]

SEEDED_KEYS = [key for key, _ in KILL_SWITCHES + FEATURE_FLAGS]


def _under_test() -> bool:
    """True when running against the test settings module (suite isolation)."""
    return settings.SETTINGS_MODULE == "config.settings.test"


def seed_flags(apps, schema_editor):
    if schema_editor is not None and _under_test():
        # Auto-run during the test DB build is skipped (see module docstring);
        # ``test_seed_flags`` calls this with ``schema_editor=None`` to verify it.
        return
    FeatureFlag = apps.get_model("featureflags", "FeatureFlag")
    for key, description in KILL_SWITCHES + FEATURE_FLAGS:
        FeatureFlag.objects.update_or_create(
            key=key,
            defaults={
                "description": description,
                "scope": "global",
                "enabled": True,
            },
        )


def unseed_flags(apps, schema_editor):
    FeatureFlag = apps.get_model("featureflags", "FeatureFlag")
    FeatureFlag.objects.filter(key__in=SEEDED_KEYS).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("featureflags", "0001_initial"),
    ]

    operations = [
        migrations.RunPython(seed_flags, unseed_flags),
    ]
