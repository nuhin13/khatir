"""Feature-flag resolution for the chatbot endpoints (EPIC-23.T-002 §10/§15).

A thin reader so the chat view never imports the feature-flag storage directly.
EPIC-13 owns :class:`~khatir.featureflags.models.FeatureFlag`; this helper
resolves the **global** ``chatbot_enabled`` flag from it when a row exists and
falls back to the task-declared default otherwise (``chatbot_enabled`` is
*default on*, kill-switchable per the epic). Keeping the read here means EPIC-13
can later change the resolution (role/user scoping, caching) without touching
the view, and T-005 seeds the actual row.
"""

from __future__ import annotations

#: Flag gating the in-app chatbot (EPIC-23 epic §"Feature flags", default on).
CHATBOT_ENABLED = "chatbot_enabled"


def is_chatbot_enabled() -> bool:
    """Return whether the global ``chatbot_enabled`` flag is on.

    Reads the global-scope :class:`FeatureFlag` row when present; if no row is
    configured the default (``True``) is returned so an unconfigured environment
    keeps the assistant available. Any storage absence resolves to the default
    rather than raising, so a missing flags table never breaks chat.
    """
    from khatir.featureflags.enums import FlagScope
    from khatir.featureflags.models import FeatureFlag

    enabled = (
        FeatureFlag.objects.filter(key=CHATBOT_ENABLED, scope=FlagScope.GLOBAL)
        .values_list("enabled", flat=True)
        .first()
    )
    return True if enabled is None else bool(enabled)
