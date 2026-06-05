"""Tests for the ``Review`` model + double-blind reveal logic (T-001 §12).

These tests are the legal guardrail for EPIC-21: they assert reviews are private
by construction, revealed only double-blind or by explicit consent, and that NO
cross-lease / public aggregation structure exists.
"""

from __future__ import annotations

import pytest
from django.db import IntegrityError, models, transaction

from khatir.accounts.tests.factories import UserFactory
from khatir.compliance.enums import ConsentType
from khatir.compliance.models import ConsentRecord
from khatir.reviews.enums import ReviewVisibility
from khatir.reviews.models import Review
from khatir.reviews.reveal import (
    both_parties_submitted,
    can_view,
    is_revealed_to_reviewee,
)

from .factories import ReviewFactory

pytestmark = pytest.mark.django_db


# ---------------------------------------------------------------------------
# Create
# ---------------------------------------------------------------------------


def test_review_create() -> None:
    review: Review = ReviewFactory(rating=4)  # type: ignore[assignment]
    assert review.pk is not None
    assert review.rating == 4
    assert review.lease_id is not None
    assert review.reviewer_id is not None
    assert review.reviewee_id is not None
    # Private by default; no consent attached.
    assert review.visibility == ReviewVisibility.PRIVATE
    assert review.consent_record_id is None
    assert review.revealed_at is None


def test_rating_must_be_1_to_5() -> None:
    for bad in (0, 6):
        with pytest.raises(IntegrityError), transaction.atomic():
            ReviewFactory(rating=bad)


def test_one_review_per_reviewer_per_lease() -> None:
    first: Review = ReviewFactory()  # type: ignore[assignment]
    with pytest.raises(IntegrityError), transaction.atomic():
        Review.objects.create(
            lease=first.lease,
            reviewer=first.reviewer,
            reviewee=first.reviewee,
            rating=3,
        )


# ---------------------------------------------------------------------------
# Double-blind reveal
# ---------------------------------------------------------------------------


def test_double_blind_reveal() -> None:
    """A review is hidden from the reviewee until the other party submits."""
    a = UserFactory()
    b = UserFactory()

    # A reviews B first. B has not reviewed A yet → NOT revealed to B.
    review_a_to_b: Review = ReviewFactory(reviewer=a, reviewee=b)  # type: ignore[assignment]
    assert both_parties_submitted(review_a_to_b) is False
    assert is_revealed_to_reviewee(review_a_to_b) is False
    # Reviewer can always see their own; reviewee cannot yet.
    assert can_view(review_a_to_b, viewer_id=a.pk) is True
    assert can_view(review_a_to_b, viewer_id=b.pk) is False

    # Now B reviews A on the SAME lease → double-blind condition met for both.
    ReviewFactory(lease=review_a_to_b.lease, reviewer=b, reviewee=a)
    review_a_to_b.refresh_from_db()
    assert both_parties_submitted(review_a_to_b) is True
    assert is_revealed_to_reviewee(review_a_to_b) is True
    assert can_view(review_a_to_b, viewer_id=b.pk) is True


def test_reciprocal_review_on_other_lease_does_not_reveal() -> None:
    """The reciprocal review must be on the SAME lease to count."""
    a = UserFactory()
    b = UserFactory()
    review_a_to_b: Review = ReviewFactory(reviewer=a, reviewee=b)  # type: ignore[assignment]
    # B reviews A but on a DIFFERENT lease → does not satisfy double-blind here.
    ReviewFactory(reviewer=b, reviewee=a)
    assert both_parties_submitted(review_a_to_b) is False
    assert is_revealed_to_reviewee(review_a_to_b) is False


def test_consent_reveals_without_double_blind() -> None:
    """Explicit logged consent reveals a review even before the other submits."""
    a = UserFactory()
    b = UserFactory()
    consent = ConsentRecord.objects.create(
        user=a, consent_type=ConsentType.PDPA_DATA_SHARING
    )
    review: Review = ReviewFactory(  # type: ignore[assignment]
        reviewer=a,
        reviewee=b,
        visibility=ReviewVisibility.CONSENTED,
        consent_record=consent,
    )
    assert both_parties_submitted(review) is False
    assert is_revealed_to_reviewee(review) is True
    assert can_view(review, viewer_id=b.pk) is True


def test_consented_visibility_without_record_does_not_reveal() -> None:
    """visibility=consented but no ConsentRecord must NOT reveal (strict)."""
    a = UserFactory()
    b = UserFactory()
    review: Review = ReviewFactory(  # type: ignore[assignment]
        reviewer=a,
        reviewee=b,
        visibility=ReviewVisibility.CONSENTED,
        consent_record=None,
    )
    assert is_revealed_to_reviewee(review) is False


def test_third_party_can_never_view() -> None:
    """Nobody outside the reviewer↔reviewee pair can view a review."""
    a = UserFactory()
    b = UserFactory()
    stranger = UserFactory()
    # Even fully revealed (both submitted), a stranger is denied.
    review: Review = ReviewFactory(reviewer=a, reviewee=b)  # type: ignore[assignment]
    ReviewFactory(lease=review.lease, reviewer=b, reviewee=a)
    assert is_revealed_to_reviewee(review) is True
    assert can_view(review, viewer_id=stranger.pk) is False


# ---------------------------------------------------------------------------
# No public / cross-lease aggregation
# ---------------------------------------------------------------------------


def test_no_aggregation_field() -> None:
    """The schema has no public/aggregate/score/reputation structure.

    Reviews must be reachable only through a single lease relationship, never
    aggregated across leases or exposed as a public reputation score.
    """
    field_names = {f.name for f in Review._meta.get_fields()}
    forbidden = {
        "is_public",
        "public",
        "aggregate_score",
        "avg_rating",
        "average_rating",
        "reputation",
        "reputation_score",
        "score",
        "searchable",
    }
    assert forbidden.isdisjoint(field_names), (
        "Review must have no public/aggregate/reputation field — that would "
        "create an illegal searchable reputation database."
    )
    # Every review is anchored to exactly one lease (the relationship).
    lease_fk = Review._meta.get_field("lease")
    assert isinstance(lease_fk, models.ForeignKey)
    assert lease_fk.null is False

    # There is no index that supports "all reviews about person X" across leases:
    # every index that touches reviewee is scoped by lease first.
    for index in Review._meta.indexes:
        if "reviewee" in index.fields:
            assert index.fields[0] == "lease", (
                "An index on reviewee not scoped by lease would enable a "
                "cross-lease reputation lookup."
            )
