"""Exhaustive rule-matrix tests for the consent-gated visibility service (T-003).

:func:`can_view_review` is the single gatekeeper for every review read path.
These tests cover the full matrix: reviewer (own), reviewee (double-blind +
consent), third party (valid consent only, logged), and default deny — plus the
ways a consent can be *invalid* (wrong subject, revoked, expired, missing).
"""

from __future__ import annotations

from datetime import timedelta

import pytest
from django.utils import timezone

from khatir.accounts.tests.factories import UserFactory
from khatir.compliance.enums import ConsentType
from khatir.compliance.models import ConsentRecord
from khatir.core.models import AuditEntry
from khatir.reviews.enums import ReviewVisibility
from khatir.reviews.models import Review
from khatir.reviews.visibility import can_view_review

from .factories import ReviewFactory

pytestmark = pytest.mark.django_db


def _consent(*, user, revoked_at=None, expires_at=None) -> ConsentRecord:
    return ConsentRecord.objects.create(
        user=user,
        consent_type=ConsentType.PDPA_DATA_SHARING,
        revoked_at=revoked_at,
        expires_at=expires_at,
    )


def _consent_reveal_logs() -> list[AuditEntry]:
    return list(AuditEntry.objects.filter(action="review.consent_reveal"))


# ---------------------------------------------------------------------------
# Reviewer — always sees their own review
# ---------------------------------------------------------------------------


def test_reviewer_sees_own() -> None:
    a = UserFactory()
    b = UserFactory()
    review: Review = ReviewFactory(reviewer=a, reviewee=b)  # type: ignore[assignment]
    assert can_view_review(review, a) is True
    # No disclosure decision was made → nothing logged.
    assert _consent_reveal_logs() == []


# ---------------------------------------------------------------------------
# Reviewee — double-blind
# ---------------------------------------------------------------------------


def test_reviewee_hidden_before_blind() -> None:
    a = UserFactory()
    b = UserFactory()
    review: Review = ReviewFactory(reviewer=a, reviewee=b)  # type: ignore[assignment]
    # B has not reviewed A yet → not revealed.
    assert can_view_review(review, b) is False


def test_reviewee_sees_after_blind() -> None:
    a = UserFactory()
    b = UserFactory()
    review: Review = ReviewFactory(reviewer=a, reviewee=b)  # type: ignore[assignment]
    # Reciprocal review on the same lease satisfies double-blind.
    ReviewFactory(lease=review.lease, reviewer=b, reviewee=a)
    assert can_view_review(review, b) is True
    # Seeing a review about yourself is not a third-party disclosure → no log.
    assert _consent_reveal_logs() == []


def test_reviewee_sees_with_consent_before_blind() -> None:
    a = UserFactory()
    b = UserFactory()
    consent = _consent(user=a)
    review: Review = ReviewFactory(  # type: ignore[assignment]
        reviewer=a,
        reviewee=b,
        visibility=ReviewVisibility.CONSENTED,
        consent_record=consent,
    )
    assert can_view_review(review, b) is True


# ---------------------------------------------------------------------------
# Third party — needs a VALID, reviewee-granted consent; logged
# ---------------------------------------------------------------------------


def test_third_party_needs_consent() -> None:
    a = UserFactory()
    b = UserFactory()
    stranger = UserFactory()
    # Even fully revealed (both submitted), a stranger is denied without consent.
    review: Review = ReviewFactory(reviewer=a, reviewee=b)  # type: ignore[assignment]
    ReviewFactory(lease=review.lease, reviewer=b, reviewee=a)
    assert can_view_review(review, stranger) is False
    assert _consent_reveal_logs() == []


def test_third_party_sees_with_reviewee_consent_and_logs() -> None:
    a = UserFactory()
    b = UserFactory()
    stranger = UserFactory()
    # Consent granted by the REVIEWEE (b) authorises disclosure of a review about b.
    consent = _consent(user=b)
    review: Review = ReviewFactory(  # type: ignore[assignment]
        reviewer=a,
        reviewee=b,
        visibility=ReviewVisibility.CONSENTED,
        consent_record=consent,
    )
    assert can_view_review(review, stranger) is True
    logs = _consent_reveal_logs()
    assert len(logs) == 1
    entry = logs[0]
    assert entry.actor_id == stranger.pk
    assert entry.target_type == "reviews.review"
    assert entry.target_id == str(review.pk)
    assert entry.after == {
        "review": review.pk,
        "reviewee": b.pk,
        "viewer": stranger.pk,
        "consent_record": consent.pk,
    }


def test_third_party_denied_when_consent_from_wrong_subject() -> None:
    """Consent must be granted by the reviewee, not the reviewer or anyone else."""
    a = UserFactory()
    b = UserFactory()
    stranger = UserFactory()
    # Consent granted by the REVIEWER (a) — does not authorise disclosure about b.
    consent = _consent(user=a)
    review: Review = ReviewFactory(  # type: ignore[assignment]
        reviewer=a,
        reviewee=b,
        visibility=ReviewVisibility.CONSENTED,
        consent_record=consent,
    )
    assert can_view_review(review, stranger) is False
    assert _consent_reveal_logs() == []


def test_third_party_denied_when_consent_revoked() -> None:
    a = UserFactory()
    b = UserFactory()
    stranger = UserFactory()
    consent = _consent(user=b, revoked_at=timezone.now())
    review: Review = ReviewFactory(  # type: ignore[assignment]
        reviewer=a,
        reviewee=b,
        visibility=ReviewVisibility.CONSENTED,
        consent_record=consent,
    )
    assert can_view_review(review, stranger) is False
    assert _consent_reveal_logs() == []


def test_third_party_denied_when_consent_expired() -> None:
    a = UserFactory()
    b = UserFactory()
    stranger = UserFactory()
    consent = _consent(user=b, expires_at=timezone.now() - timedelta(days=1))
    review: Review = ReviewFactory(  # type: ignore[assignment]
        reviewer=a,
        reviewee=b,
        visibility=ReviewVisibility.CONSENTED,
        consent_record=consent,
    )
    assert can_view_review(review, stranger) is False
    assert _consent_reveal_logs() == []


def test_third_party_sees_with_unexpired_consent() -> None:
    a = UserFactory()
    b = UserFactory()
    stranger = UserFactory()
    consent = _consent(user=b, expires_at=timezone.now() + timedelta(days=1))
    review: Review = ReviewFactory(  # type: ignore[assignment]
        reviewer=a,
        reviewee=b,
        visibility=ReviewVisibility.CONSENTED,
        consent_record=consent,
    )
    assert can_view_review(review, stranger) is True
    assert len(_consent_reveal_logs()) == 1


# ---------------------------------------------------------------------------
# Default deny
# ---------------------------------------------------------------------------


def test_default_deny() -> None:
    """A stranger with no consent attached is denied — the default."""
    a = UserFactory()
    b = UserFactory()
    stranger = UserFactory()
    review: Review = ReviewFactory(reviewer=a, reviewee=b)  # type: ignore[assignment]
    assert review.consent_record_id is None
    assert can_view_review(review, stranger) is False
    assert _consent_reveal_logs() == []


def test_default_deny_consented_visibility_without_record() -> None:
    """visibility=consented but no ConsentRecord → still denied (strict)."""
    a = UserFactory()
    b = UserFactory()
    stranger = UserFactory()
    review: Review = ReviewFactory(  # type: ignore[assignment]
        reviewer=a,
        reviewee=b,
        visibility=ReviewVisibility.CONSENTED,
        consent_record=None,
    )
    assert can_view_review(review, stranger) is False
    assert _consent_reveal_logs() == []
