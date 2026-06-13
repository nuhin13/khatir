"""Feature-flag resolution for the gov-export endpoints (EPIC-26 T-004 §6–10).

A thin, abstracted reader so the export views never import the feature-flag
storage directly. EPIC-13 owns the :class:`~khatir.featureflags.models.FeatureFlag`
model; this helper resolves the **global** ``gov_export_enabled`` flag from it
when a row exists and falls back to the task-declared default otherwise
(``gov_export_enabled`` is **default OFF** — EPIC-26 T-004/T-005). Keeping the
read here means EPIC-13 can later swap the resolution (role/user scoping,
caching) without touching the views.
"""

from __future__ import annotations

#: Flag gating the whole gov-export feature (EPIC-26 T-004 §6–10, default OFF).
GOV_EXPORT_ENABLED = "gov_export_enabled"


def is_feature_enabled(key: str, *, default: bool) -> bool:
    """Return whether the global feature flag ``key`` is enabled.

    Reads the global-scope :class:`FeatureFlag` row when present; if no row is
    configured the ``default`` is returned (so an unconfigured environment keeps
    the task-declared default behaviour). Any storage absence resolves to the
    default rather than raising, so a missing flags table never breaks a request.
    """
    from khatir.featureflags.enums import FlagScope
    from khatir.featureflags.models import FeatureFlag

    flag = (
        FeatureFlag.objects.filter(key=key, scope=FlagScope.GLOBAL)
        .values_list("enabled", flat=True)
        .first()
    )
    return default if flag is None else bool(flag)


def gov_export_enabled() -> bool:
    """Whether the gov-export feature is live (global flag, default OFF)."""
    return is_feature_enabled(GOV_EXPORT_ENABLED, default=False)
