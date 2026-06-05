"""Reviews-domain enums — EPIC-21 (mutual private reviews).

Domain-specific (used only by ``Review``), so they live in the owning app
rather than ``khatir.core.enums``. Wire values are the single source of truth
in ``docs/architecture/enums.md`` — lowercase snake_case strings, never
integers.
"""

from django.db import models


class ReviewVisibility(models.TextChoices):
    """Who may see a review beyond the system itself.

    ``PRIVATE`` is the default and the legal floor: a review is revealed to the
    reviewee only via the double-blind rule (both parties submitted). Any value
    beyond ``PRIVATE`` requires an explicit, logged ``ConsentRecord`` — there is
    no public or cross-lease aggregation value, by design.
    """

    PRIVATE = "private", "Private"
    CONSENTED = "consented", "Consented"
