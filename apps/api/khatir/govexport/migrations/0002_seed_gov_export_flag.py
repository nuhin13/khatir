"""Seed the ``gov_export_enabled`` feature flag — DEFAULT OFF (EPIC-26.T-005).

So the gov-export wedge ships *dark*: the global ``gov_export_enabled``
:class:`~khatir.featureflags.models.FeatureFlag` row exists from day one but is
seeded ``enabled=False``, and an admin flips it ON to release the feature. The
export endpoints (EPIC-26.T-004) resolve this flag (default OFF) before doing any
work, so the seeded row simply makes the OFF state explicit/visible in the admin.

EPIC-13 owns the ``FeatureFlag`` model; this migration only inserts a row, so it
depends on ``featureflags.0002_seed_flags`` (table + baseline flags present) and
uses the literal wire value ``"global"`` for ``scope`` rather than importing the
``FlagScope`` enum (migrations never import app code).

Idempotent (``update_or_create`` keyed on the unique ``key``) and reversible
(reverse removes exactly this key).

**Test isolation:** mirrors ``featureflags.0002_seed_flags`` — the seed is a
no-op when auto-run under the test settings module so it does not pollute the
EPIC-26.T-004 endpoint tests, which assert default-OFF behaviour against an empty
flags table and build their own ``gov_export_enabled`` rows.
``test_seed_gov_export_flag`` invokes ``seed_gov_export_flag`` directly to verify
it. Dev/prod always run the seed.
"""

from django.conf import settings
from django.db import migrations

GOV_EXPORT_FLAG_KEY = "gov_export_enabled"
GOV_EXPORT_FLAG_DESCRIPTION = (
    "Government-submission export feature (EPIC-26). Default OFF — admin flips ON to release."
)


def _under_test() -> bool:
    """True when running against the test settings module (suite isolation)."""
    return settings.SETTINGS_MODULE == "config.settings.test"


def seed_gov_export_flag(apps, schema_editor):
    if schema_editor is not None and _under_test():
        # Auto-run during the test DB build is skipped (see module docstring);
        # ``test_seed_gov_export_flag`` calls this with ``schema_editor=None``.
        return
    FeatureFlag = apps.get_model("featureflags", "FeatureFlag")
    FeatureFlag.objects.update_or_create(
        key=GOV_EXPORT_FLAG_KEY,
        defaults={
            "description": GOV_EXPORT_FLAG_DESCRIPTION,
            "scope": "global",
            "enabled": False,
        },
    )


def unseed_gov_export_flag(apps, schema_editor):
    FeatureFlag = apps.get_model("featureflags", "FeatureFlag")
    FeatureFlag.objects.filter(key=GOV_EXPORT_FLAG_KEY).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("govexport", "0001_initial"),
        ("featureflags", "0002_seed_flags"),
    ]

    operations = [
        migrations.RunPython(seed_gov_export_flag, unseed_gov_export_flag),
    ]
