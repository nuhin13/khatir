"""Seed the ``ai_lease_enabled`` feature flag (EPIC-18.T-005, default on).

The AI lease-document generation endpoints (EPIC-18) are gated behind a global
feature flag so the feature can be killed without a redeploy. It ships
``enabled=True`` (feature live); the admin flips it OFF to disable AI-lease
generation. ``leasedocs/flags.py`` reads this row and falls back to ``True``
when absent, so an unconfigured environment keeps the declared default.

Idempotent (``update_or_create`` keyed on the unique ``key``) and reversible
(reverse removes exactly this key). Migrations never import app code, so the
scope uses the literal wire value ``"global"`` rather than the ``FlagScope``
enum.

**Test isolation:** like ``0002_seed_flags``, the seed is a no-op under the test
settings module so it never pollutes the featureflags / leasedocs flag tests,
which build their own rows. ``test_seed_ai_lease_flag`` invokes ``seed_flag``
directly to verify it. Dev/prod always run the seed.
"""

from django.conf import settings
from django.db import migrations

FLAG_KEY = "ai_lease_enabled"
FLAG_DESCRIPTION = "AI lease-document generation endpoints (EPIC-18)."


def _under_test() -> bool:
    """True when running against the test settings module (suite isolation)."""
    return settings.SETTINGS_MODULE == "config.settings.test"


def seed_flag(apps, schema_editor):
    if schema_editor is not None and _under_test():
        # Skipped during the test DB build (see module docstring);
        # ``test_seed_ai_lease_flag`` calls this with ``schema_editor=None``.
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


def unseed_flag(apps, schema_editor):
    FeatureFlag = apps.get_model("featureflags", "FeatureFlag")
    FeatureFlag.objects.filter(key=FLAG_KEY).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("featureflags", "0002_seed_flags"),
    ]

    operations = [
        migrations.RunPython(seed_flag, unseed_flag),
    ]
