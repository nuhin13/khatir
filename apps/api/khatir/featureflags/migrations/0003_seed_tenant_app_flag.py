"""Seed the ``tenant_app_enabled`` feature flag, default on (EPIC-19.T-013).

So the tenant-facing app ships enabled from day one. Convention matches
``0002_seed_flags``: ``enabled=True`` = feature IS ON; an admin flips it to
``False`` to disable the whole tenant app.

Idempotent (``update_or_create`` keyed on the unique ``key``) and reversible
(reverse removes exactly this key). Migrations never import app code, so the
flag definition stays frozen against future model/enum changes; ``scope`` uses
the literal wire value ``"global"`` rather than the ``FlagScope`` enum.

**Test isolation:** like ``0002_seed_flags``, the seed is a no-op when auto-run
under the test settings module so it does not pollute the featureflags endpoint
tests that assert an empty table. ``test_seed_tenant_app_flag`` invokes
``seed_tenant_app_flag`` directly to verify it. Dev/prod always run the seed.
"""

from django.conf import settings
from django.db import migrations

TENANT_APP_FLAG_KEY = "tenant_app_enabled"
TENANT_APP_FLAG_DESCRIPTION = "Tenant-facing mobile app (EPIC-19)."


def _under_test() -> bool:
    """True when running against the test settings module (suite isolation)."""
    return settings.SETTINGS_MODULE == "config.settings.test"


def seed_tenant_app_flag(apps, schema_editor):
    if schema_editor is not None and _under_test():
        # Auto-run during the test DB build is skipped (see module docstring);
        # ``test_seed_tenant_app_flag`` calls this with ``schema_editor=None``.
        return
    FeatureFlag = apps.get_model("featureflags", "FeatureFlag")
    FeatureFlag.objects.update_or_create(
        key=TENANT_APP_FLAG_KEY,
        defaults={
            "description": TENANT_APP_FLAG_DESCRIPTION,
            "scope": "global",
            "enabled": True,
        },
    )


def unseed_tenant_app_flag(apps, schema_editor):
    FeatureFlag = apps.get_model("featureflags", "FeatureFlag")
    FeatureFlag.objects.filter(key=TENANT_APP_FLAG_KEY).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("featureflags", "0002_seed_flags"),
    ]

    operations = [
        migrations.RunPython(seed_tenant_app_flag, unseed_tenant_app_flag),
    ]
