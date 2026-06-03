"""Feature-flags domain enums — Domain 8 of ``06_database_schema.md``.

``FlagScope`` is domain-specific to this app and not shared across apps,
so it lives here rather than in ``khatir.core.enums``. Wire values are
lowercase snake_case strings per ``docs/architecture/enums.md``.
"""

from django.db import models


class FlagScope(models.TextChoices):
    """Scope of a FeatureFlag — at what level it applies."""

    GLOBAL = "global", "Global"
    ROLE = "role", "Role"
    USER = "user", "User"


class KillSwitchAction(models.TextChoices):
    """The action recorded in a KillSwitchEvent."""

    DISABLE = "disable", "Disable"
    ENABLE = "enable", "Enable"
