"""Account-domain enums.

``Role`` and ``Language`` are genuinely cross-app and therefore canonically
defined in ``khatir.core.enums``. They are re-exported here so accounts-domain
code (and future imports) can reference them from the owning app without
reaching past the public surface, exactly as ``enums.md`` lists them. The wire
values are the single source of truth in ``docs/architecture/enums.md``.
"""

from khatir.core.enums import Language, Role

__all__ = ["Language", "Role"]
