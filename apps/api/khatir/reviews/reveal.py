"""Double-blind reveal logic for mutual reviews — the legal heart of EPIC-21.

A review about you is visible to you **only** when:

1. **Double-blind**: both parties to the lease have submitted their review of the
   other (so nobody can read the other's rating before committing their own), OR
2. **Consent**: the reviewer attached an explicit, logged ``ConsentRecord`` that
   authorises visibility (``visibility == CONSENTED`` with a non-null
   ``consent_record``).

There is **no** path that reveals a review across leases or to a non-party. The
viewer must always be the reviewee of the specific review.

Keep this strict: when in doubt, a review stays private.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

from .enums import ReviewVisibility

if TYPE_CHECKING:
    from .models import Review


def both_parties_submitted(review: Review) -> bool:
    """True when both lease parties have a (live) review on this lease.

    The double-blind condition: a reveal is allowed once the reviewer's
    counterpart has also submitted a review for the same lease. We check for the
    *reciprocal* review — same lease, authored by this review's reviewee — so a
    party cannot read the other's review before writing their own.
    """
    from .models import Review

    return (
        Review.objects.filter(
            lease_id=review.lease_id,
            reviewer_id=review.reviewee_id,
            reviewee_id=review.reviewer_id,
        )
        .exclude(pk=review.pk)
        .exists()
    )


def is_revealed_to_reviewee(review: Review) -> bool:
    """Whether ``review`` may be shown to its reviewee.

    Revealed iff the double-blind condition is met OR explicit consent was
    granted. Never revealed to anyone other than the reviewee.
    """
    if review.visibility == ReviewVisibility.CONSENTED and review.consent_record_id is not None:
        return True
    return both_parties_submitted(review)


def can_view(review: Review, *, viewer_id: int) -> bool:
    """Whether the user ``viewer_id`` may read ``review``.

    - The reviewer can always read their own review.
    - The reviewee can read it only once it is revealed (double-blind/consent).
    - Everyone else: never. There is no public or cross-party access.
    """
    if viewer_id == review.reviewer_id:
        return True
    if viewer_id == review.reviewee_id:
        return is_revealed_to_reviewee(review)
    return False
