"""Feature-flag resolution for the lease-document endpoints (EPIC-18 · T-005 §10).

A thin reader so the views never import the feature-flag storage directly.
EPIC-13 owns :class:`~khatir.featureflags.models.FeatureFlag`; this helper
resolves a **global** flag from it when a row exists and falls back to the
task-declared default otherwise (``ai_lease_enabled`` is *default on*; T-005
seeds the row). A missing flags table resolves to the default rather than
raising, so an unconfigured environment keeps the declared behaviour.
"""

from __future__ import annotations

#: Flag gating AI lease-document generation (EPIC-18 §10, default on).
AI_LEASE_ENABLED = "ai_lease_enabled"


def is_feature_enabled(key: str, *, default: bool) -> bool:
    """Return whether the global feature flag ``key`` is enabled (else ``default``)."""
    from khatir.featureflags.enums import FlagScope
    from khatir.featureflags.models import FeatureFlag

    flag = (
        FeatureFlag.objects.filter(key=key, scope=FlagScope.GLOBAL)
        .values_list("enabled", flat=True)
        .first()
    )
    return default if flag is None else bool(flag)
