"""Feature-flag (kill-switch) resolution for the warnings endpoints (T-002 §10).

A thin reader so the warning views never import the feature-flag storage
directly. EPIC-13 owns the :class:`~khatir.featureflags.models.FeatureFlag`
model and seeds the ``warnings_feature`` **kill-switch** as a global flag (T-004).

Kill-switch convention (EPIC-13.T-004 §15): ``enabled=True`` means the feature is
LIVE; flipping it to ``enabled=False`` is what KILLS the feature. The switch is
seeded live, so an unseeded environment defaults to live as well — the test that
exercises the kill path creates the flag explicitly with ``enabled=False``.
"""

from __future__ import annotations

#: Kill-switch gating the entire private-warnings feature (T-002 §10).
WARNINGS_FEATURE = "warnings_feature"


def is_warnings_feature_enabled() -> bool:
    """Return whether the ``warnings_feature`` kill-switch is live.

    Reads the global-scope :class:`FeatureFlag` row when present; if no row is
    configured the feature defaults to live (the switch ships seeded ``enabled``
    — T-004). Any storage absence resolves to the default rather than raising, so
    a missing flags table never breaks the gate.
    """
    from khatir.featureflags.enums import FlagScope
    from khatir.featureflags.models import FeatureFlag

    enabled = (
        FeatureFlag.objects.filter(key=WARNINGS_FEATURE, scope=FlagScope.GLOBAL)
        .values_list("enabled", flat=True)
        .first()
    )
    return True if enabled is None else bool(enabled)
