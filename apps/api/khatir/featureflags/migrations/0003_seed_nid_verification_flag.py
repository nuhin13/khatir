"""Seed the ``nid_verification_enabled`` feature flag (EPIC-17.T-005).

The NID/EC verification feature (EPIC-17) is gated by a single global kill-switch
flag, ``nid_verification_enabled``. It is seeded **enabled=True (default on)**: the
feature is live by default and an admin flips it OFF if the EC API or a legal issue
arises (EPIC-17 ``_epic.md`` §risks). ``khatir.verification.flags.is_feature_enabled``
already falls back to *on* when no row exists, but seeding an explicit row makes the
switch visible and editable in the admin from day one.

Idempotent (``update_or_create`` keyed on the unique ``key``) and reversible (reverse
removes exactly this key). Migrations never import app code, so ``scope`` uses the
literal wire value ``"global"`` rather than the ``FlagScope`` enum.

**Test isolation:** like the baseline ``0002_seed_flags`` migration, the seed is a
no-op under the test settings module so it never pollutes the EPIC-13 flag-endpoint
tests (which assert against an empty flags table) or the EPIC-17 verify-API tests
(which assert the default-on fallback with *no* row present). ``test_seed_flags``
invokes ``seed_nid_verification_flag`` directly to verify it. Dev/prod always run it.
"""

from django.conf import settings
from django.db import migrations

FLAG_KEY = "nid_verification_enabled"
FLAG_DESCRIPTION = (
    "NID/EC verification kill-switch (EPIC-17). On = feature live; "
    "flip OFF to disable all EC verification."
)


def _under_test() -> bool:
    """True when running against the test settings module (suite isolation)."""
    return settings.SETTINGS_MODULE == "config.settings.test"


def seed_nid_verification_flag(apps, schema_editor):
    if schema_editor is not None and _under_test():
        # Auto-run during the test DB build is skipped (see module docstring);
        # the test calls this with ``schema_editor=None`` to verify it.
        return
    FeatureFlag = apps.get_model("featureflags", "FeatureFlag")
    FeatureFlag.objects.update_or_create(
        key=FLAG_KEY,
        defaults={
            "description": FLAG_DESCRIPTION,
            "scope": "global",
            "enabled": True,
        },
    )


def unseed_nid_verification_flag(apps, schema_editor):
    FeatureFlag = apps.get_model("featureflags", "FeatureFlag")
    FeatureFlag.objects.filter(key=FLAG_KEY).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("featureflags", "0002_seed_flags"),
    ]

    operations = [
        migrations.RunPython(
            seed_nid_verification_flag, unseed_nid_verification_flag
        ),
    ]
