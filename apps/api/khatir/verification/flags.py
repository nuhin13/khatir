"""Feature-flag resolution for the verification endpoint (EPIC-17 T-004 §10).

A thin, abstracted reader so the verify view never imports the feature-flag
storage directly. EPIC-13 owns the :class:`~khatir.featureflags.models.FeatureFlag`
model; this helper resolves a **global** flag from it when a row exists and falls
back to the task-declared default otherwise (``nid_verification_enabled`` is
*default on* — it is the kill-switch for the whole EC verification feature, flipped
off if the EC API or a legal issue arises, EPIC-17 ``_epic.md`` §risks). Keeping the
read here means EPIC-13 can later swap the resolution (scoping, caching) without
touching the view.
"""

from __future__ import annotations

#: Kill-switch flag for the NID/EC verification feature (EPIC-17, default on).
NID_VERIFICATION_ENABLED = "nid_verification_enabled"


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
