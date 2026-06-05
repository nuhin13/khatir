"""Feature-flag resolution for the manager (B2B) endpoints (EPIC-22 §10).

A thin reader so the manager views never import the feature-flag storage
directly. EPIC-13 owns the :class:`~khatir.featureflags.models.FeatureFlag`
model; this helper resolves the global ``b2b_manager_enabled`` flag from it when
a row exists and falls back to the task-declared default otherwise. Keeping the
read here means EPIC-13 can later swap the resolution (e.g. role/user scoping,
caching) without touching the views.
"""

from __future__ import annotations

#: Flag gating the B2B manager endpoints (EPIC-22 §10). Default **off** — the
#: B2B manager surface is opt-in until rolled out.
B2B_MANAGER_ENABLED = "b2b_manager_enabled"


def is_b2b_manager_enabled() -> bool:
    """Whether the ``b2b_manager_enabled`` global feature flag is on.

    Reads the global-scope :class:`FeatureFlag` row when present; a missing row
    (or an absent flags table) resolves to the task-declared default of *off*,
    so an unconfigured environment never silently exposes the manager surface.
    """
    from khatir.tenants.flags import is_feature_enabled

    return is_feature_enabled(B2B_MANAGER_ENABLED, default=False)
