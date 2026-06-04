"""Feature-flag resolution for the tenants endpoints (EPIC-04.T-006 §10/§15).

A thin, abstracted reader so the voice endpoint never imports the feature-flag
storage directly. EPIC-13 owns the :class:`~khatir.featureflags.models.FeatureFlag`
model; this helper resolves a **global** flag from it when a row exists and falls
back to the task-declared default otherwise (``voice_tenant_entry`` is *default
on*). Keeping the read here means EPIC-13 can later swap the resolution
(e.g. role/user scoping, caching) without touching the view.
"""

from __future__ import annotations

#: Flag gating the voice tenant-entry endpoint (EPIC-04.T-006 §10, default on).
VOICE_TENANT_ENTRY = "voice_tenant_entry"


def is_feature_enabled(key: str, *, default: bool) -> bool:
    """Return whether the global feature flag ``key`` is enabled.

    Reads the global-scope :class:`FeatureFlag` row when present; if no row is
    configured the ``default`` is returned (so an unconfigured environment keeps
    the task-declared default behaviour). Any storage absence resolves to the
    default rather than raising, so a missing flags table never breaks intake.
    """
    from khatir.featureflags.enums import FlagScope
    from khatir.featureflags.models import FeatureFlag

    flag = (
        FeatureFlag.objects.filter(key=key, scope=FlagScope.GLOBAL)
        .values_list("enabled", flat=True)
        .first()
    )
    return default if flag is None else bool(flag)
