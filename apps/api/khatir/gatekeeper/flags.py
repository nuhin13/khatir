"""Feature-flag resolution for the gatekeeper endpoints (T-002 §10/§15).

A thin reader so gatekeeper views never import the feature-flag storage directly.
EPIC-13 owns the :class:`~khatir.featureflags.models.FeatureFlag` model; this
helper resolves the **global** ``gatekeeper_enabled`` flag when a row exists and
falls back to the task-declared default otherwise (default *on*, seeded by
EPIC-25.T-012). Keeping the read here means EPIC-13 can later swap the resolution
(role/user scoping, caching) without touching the views.
"""

from __future__ import annotations

#: Flag gating the gatekeeper (caretaker/visitor) endpoints (T-002 §10, default on).
GATEKEEPER_ENABLED = "gatekeeper_enabled"


def is_gatekeeper_enabled(*, default: bool = True) -> bool:
    """Return whether the global ``gatekeeper_enabled`` feature flag is enabled.

    Reads the global-scope :class:`FeatureFlag` row when present; if no row is
    configured the ``default`` is returned (so an unconfigured environment keeps
    the task-declared default). Any storage absence resolves to the default
    rather than raising, so a missing flags table never breaks the endpoints.
    """
    from khatir.featureflags.enums import FlagScope
    from khatir.featureflags.models import FeatureFlag

    flag = (
        FeatureFlag.objects.filter(key=GATEKEEPER_ENABLED, scope=FlagScope.GLOBAL)
        .values_list("enabled", flat=True)
        .first()
    )
    return default if flag is None else bool(flag)
