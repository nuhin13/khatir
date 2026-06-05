"""Seed the gatekeeper feature flag + visitor-log retention config (EPIC-25.T-012).

So the gate visitor module ships live from day one and ops can tune the
visitor-log retention window without a redeploy:

* ``gatekeeper_enabled`` (:class:`~khatir.featureflags.models.FeatureFlag`,
  global scope, ``enabled=True``) — gates the caretaker/visitor endpoints
  (consumed by :mod:`khatir.gatekeeper.flags`; default *on*).
* ``visitor_log_retention_days`` (:class:`~khatir.core.models.SystemConfig`,
  ``int`` = ``90``) — days a ``VisitorLog`` (incl. its photo) is retained
  before purge (``03_env_and_config.md`` §4; ``06_database_schema.md`` §
  VisitorLog: "90-day retention").

Migrations never import app code, so the literals stay frozen against future
model/enum changes (scope uses the wire value ``"global"``, type the wire value
``"int"``). Both seeds are idempotent (``update_or_create`` keyed on the unique
``key``) and the reverse removes exactly the keys each added.

**Test isolation:** the *flag* seed mirrors EPIC-13.T-004's convention and is a
no-op under the test settings module so it cannot pollute the featureflags
endpoint tests; ``test_seed_gatekeeper_config`` invokes ``seed_gatekeeper_flag``
directly to verify it. The *config* seed follows core's convention and always
runs (the core ``SystemConfig`` seeds are present in the test DB), so the
``visitor_log_retention_days`` row is asserted straight from the migrated DB.
"""

from django.conf import settings
from django.db import migrations

#: Global feature flag gating the gatekeeper endpoints (T-012, default on).
GATEKEEPER_FLAG_KEY = "gatekeeper_enabled"

#: SystemConfig key/value for the visitor-log retention window (int days).
RETENTION_CONFIG = {
    "key": "visitor_log_retention_days",
    "value": "90",
    "type": "int",
    "description": "Days a visitor log (and its photo) is retained before purge.",
}


def _under_test() -> bool:
    """True when running against the test settings module (suite isolation)."""
    return settings.SETTINGS_MODULE == "config.settings.test"


def seed_gatekeeper_flag(apps, schema_editor):
    if schema_editor is not None and _under_test():
        # Skipped during the test DB build (see module docstring);
        # ``test_seed_gatekeeper_config`` calls this with schema_editor=None.
        return
    FeatureFlag = apps.get_model("featureflags", "FeatureFlag")
    FeatureFlag.objects.update_or_create(
        key=GATEKEEPER_FLAG_KEY,
        defaults={
            "description": "Gate visitor / caretaker module (EPIC-25).",
            "scope": "global",
            "enabled": True,
        },
    )


def unseed_gatekeeper_flag(apps, schema_editor):
    FeatureFlag = apps.get_model("featureflags", "FeatureFlag")
    FeatureFlag.objects.filter(key=GATEKEEPER_FLAG_KEY).delete()


def seed_retention_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    SystemConfig.objects.update_or_create(
        key=RETENTION_CONFIG["key"],
        defaults={
            "value": RETENTION_CONFIG["value"],
            "type": RETENTION_CONFIG["type"],
            "description": RETENTION_CONFIG["description"],
        },
    )


def unseed_retention_config(apps, schema_editor):
    SystemConfig = apps.get_model("core", "SystemConfig")
    SystemConfig.objects.filter(key=RETENTION_CONFIG["key"]).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("gatekeeper", "0001_initial"),
        ("featureflags", "0002_seed_flags"),
        ("core", "0012_seed_compliance_config"),
    ]

    operations = [
        migrations.RunPython(seed_gatekeeper_flag, unseed_gatekeeper_flag),
        migrations.RunPython(seed_retention_config, unseed_retention_config),
    ]
