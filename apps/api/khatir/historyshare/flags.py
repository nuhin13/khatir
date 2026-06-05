"""Feature-flag (kill-switch) resolution for the history-sharing endpoints.

EPIC-13 owns the :class:`~khatir.featureflags.models.FeatureFlag` model and the
``history_flags_feature`` kill-switch (seeded ``enabled=True`` — feature live;
an admin flips it to ``enabled=False`` to KILL the whole feature). This thin
reader keeps the views/services from importing the flag storage directly, so
EPIC-13 can later change resolution (caching, scoping) without touching us.

The flag is read as a **global** flag and resolves to its task-declared default
when no row exists, so an un-seeded environment keeps the feature live rather
than 500ing on a missing flags table.
"""

from __future__ import annotations

#: Kill-switch gating ALL tenant-initiated history sharing (EPIC-24, EPIC-13.T-004).
HISTORY_FLAGS_FEATURE = "history_flags_feature"


def history_sharing_enabled() -> bool:
    """Return whether the ``history_flags_feature`` kill-switch is live.

    ``True`` = feature ON (default, matching the seeded state). When the admin
    throws the kill-switch the flag row is ``enabled=False`` and this returns
    ``False`` so every share endpoint refuses the action.
    """
    from khatir.tenants.flags import is_feature_enabled

    return is_feature_enabled(HISTORY_FLAGS_FEATURE, default=True)
