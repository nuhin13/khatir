"""Consent-gated visibility service — EPIC-21.T-003.

This is the **single** gatekeeper that decides whether a given review is visible
to a given viewer. Every read path must go through :func:`can_view_review`; if a
review is not visible here, it is not visible anywhere.

The rule matrix (default **deny**):

================  ====================================================  ============
Viewer            Condition                                             Visible?
================  ====================================================  ============
reviewer          always (it is their own review)                      yes
reviewee          double-blind satisfied OR explicit consent attached  yes
any other viewer  a *valid* ``ConsentRecord`` from the **reviewee**     yes (logged)
                  authorises the disclosure
anyone else       —                                                    no
================  ====================================================  ============

A "valid" consent is one that is granted, not revoked, and not expired (see
:func:`_consent_is_valid`). Every consent-based reveal to a third party is
written to the audit trail (``review.consent_reveal``) — non-consent paths
(reviewer/reviewee) are not logged because no disclosure decision is being made.

There is deliberately **no** path that grants cross-lease or public/aggregate
access. A third party can only ever see a single review, and only when the
reviewee has logged consent authorising that disclosure.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

from django.utils import timezone

from khatir.core.audit import audit

from . import reveal

if TYPE_CHECKING:
    from khatir.accounts.models import User

    from .models import Review


def _consent_is_valid(consent_record, *, reviewee_id: int) -> bool:
    """Whether ``consent_record`` validly authorises a third-party disclosure.

    Valid means: it exists, it was granted by the **reviewee** (the data subject
    of the review), it has not been revoked, and it has not expired. A consent
    granted by anyone other than the reviewee can never authorise disclosure of
    a review about them.
    """
    if consent_record is None:
        return False
    if consent_record.user_id != reviewee_id:
        return False
    if consent_record.revoked_at is not None:
        return False
    now = timezone.now()
    if consent_record.expires_at is not None and consent_record.expires_at <= now:
        return False
    return True


def _log_consent_reveal(review: Review, *, viewer: User) -> None:
    """Record a third-party consent-based disclosure on the audit trail."""
    audit(
        actor=viewer,
        action="review.consent_reveal",
        target=review,
        before=None,
        after={
            "review": review.pk,
            "reviewee": review.reviewee_id,
            "viewer": viewer.pk,
            "consent_record": review.consent_record_id,
        },
    )


def can_view_review(review: Review, viewer: User) -> bool:
    """Whether ``viewer`` may read ``review`` — the single visibility gate.

    - The **reviewer** can always read their own review.
    - The **reviewee** can read it once it is revealed (double-blind met, or
      consent attached).
    - **Any other viewer** can read it only when the review carries a *valid*
      ``ConsentRecord`` granted by the reviewee; such a disclosure is logged.
    - Everyone else: denied. This is the default.
    """
    viewer_id = viewer.pk

    # Reviewer always sees their own review — no disclosure decision, no log.
    if viewer_id == review.reviewer_id:
        return True

    # Reviewee sees it once revealed (double-blind or consent). No log: seeing a
    # review about yourself is not a third-party disclosure.
    if viewer_id == review.reviewee_id:
        return reveal.is_revealed_to_reviewee(review)

    # Any other viewer: only with a valid, reviewee-granted consent record, and
    # the disclosure is always logged.
    if review.consent_record_id is not None and _consent_is_valid(
        review.consent_record, reviewee_id=review.reviewee_id
    ):
        _log_consent_reveal(review, viewer=viewer)
        return True

    # Default deny — there is no other path to visibility.
    return False
