"""Reviews services — EPIC-21.T-002 (kill-switch + relationship + audit).

The endpoint layer stays thin; all the business rules live here:

- :func:`reviews_feature_enabled` resolves the ``reviews_feature`` kill-switch
  (EPIC-13). The switch is a global flag; ``enabled`` ⇒ feature live. When no row
  exists the feature defaults **on** (kill-switches are off only when an admin
  has explicitly flipped them), matching the seed convention.
- :func:`lease_parties` returns the two — and only two — users a review may flow
  between for a given lease: the landlord and the tenant's linked app user.
- :func:`submit_review` enforces "lease party only", "one review per party per
  lease", and writes an audit row.
- :func:`reviews_about` returns the reviews *about* a user, reveal-filtered.

There is deliberately no function that looks up reviews about an arbitrary
person or aggregates ratings — that is the illegal public-reputation feature
the epic forbids by construction.
"""

from __future__ import annotations

from dataclasses import dataclass

from django.db import IntegrityError, transaction

from khatir.accounts.models import User
from khatir.core.audit import audit
from khatir.leases.models import Lease

from .models import Review

#: The kill-switch flag key (EPIC-13.T-004) gating the whole reviews feature.
REVIEWS_FEATURE_FLAG = "reviews_feature"


class ReviewsFeatureDisabled(Exception):
    """Raised when the ``reviews_feature`` kill-switch is off — view maps to 403."""


class NotALeaseParty(Exception):
    """Raised when the actor is neither the landlord nor the tenant of a lease."""


class AlreadyReviewed(Exception):
    """Raised when a party tries to submit a second review for the same lease."""


def reviews_feature_enabled() -> bool:
    """Whether the ``reviews_feature`` kill-switch is live.

    Reads the global :class:`FeatureFlag` row; absence resolves to the
    kill-switch default (**on**), so an un-seeded environment still offers the
    feature and only an explicit admin flip to ``False`` kills it.
    """
    from khatir.featureflags.enums import FlagScope
    from khatir.featureflags.models import FeatureFlag

    enabled = (
        FeatureFlag.objects.filter(key=REVIEWS_FEATURE_FLAG, scope=FlagScope.GLOBAL)
        .values_list("enabled", flat=True)
        .first()
    )
    return True if enabled is None else bool(enabled)


@dataclass(frozen=True)
class LeaseParties:
    """The two users a review may flow between for a lease.

    ``tenant_user`` is ``None`` when the tenant has no linked app account — such a
    tenant cannot be a reviewer or reviewee yet.
    """

    landlord: User
    tenant_user: User | None

    def counterpart_of(self, user: User) -> User | None:
        """Return the other party relative to ``user`` (or ``None`` if not a party)."""
        if user.pk == self.landlord_id:
            return self.tenant_user
        if self.tenant_user is not None and user.pk == self.tenant_user.pk:
            return self.landlord
        return None

    @property
    def landlord_id(self) -> int:
        return self.landlord.pk

    def is_party(self, user: User) -> bool:
        return self.counterpart_of(user) is not None


def lease_parties(lease: Lease) -> LeaseParties:
    """Resolve the landlord and the tenant's linked user for ``lease``."""
    tenant_user = lease.tenant.linked_user
    return LeaseParties(landlord=lease.landlord, tenant_user=tenant_user)


@transaction.atomic
def submit_review(
    *,
    actor: User,
    lease: Lease,
    rating: int,
    comment: str = "",
) -> Review:
    """Create a review by ``actor`` about their lease counterpart.

    Enforces (in order): the actor is one of the two lease parties, and the
    counterpart resolves to a concrete user. The unique constraint
    (``lease`` + ``reviewer``) backstops "one review per party per lease"; a
    duplicate raises :class:`AlreadyReviewed`. Writes an audit row.

    Raises :class:`NotALeaseParty` / :class:`AlreadyReviewed` — the view maps
    them to 403 / 409 respectively.
    """
    parties = lease_parties(lease)
    reviewee = parties.counterpart_of(actor)
    if reviewee is None:
        raise NotALeaseParty(
            "Only the landlord or tenant of this lease may submit a review."
        )

    try:
        with transaction.atomic():
            review = Review.objects.create(
                lease=lease,
                reviewer=actor,
                reviewee=reviewee,
                rating=rating,
                comment=comment,
            )
    except IntegrityError as exc:
        raise AlreadyReviewed(
            "You have already submitted a review for this lease."
        ) from exc

    audit(
        actor=actor,
        action="review.submit",
        target=review,
        before=None,
        after={
            "lease": lease.pk,
            "reviewer": actor.pk,
            "reviewee": reviewee.pk,
            "rating": rating,
        },
    )
    return review


def reviews_about(user: User) -> list[Review]:
    """Reviews *about* ``user`` (where they are the reviewee), reveal-filtered.

    Scoped strictly to ``reviewee == user``; there is no path to read reviews
    about anyone else. Each row is included only when the reveal helper says it
    may be shown to this viewer — the masking of non-revealed rows is applied by
    the view via :mod:`khatir.reviews.reveal`.
    """
    return list(
        Review.objects.filter(reviewee=user).select_related(
            "lease", "reviewer", "reviewee"
        )
    )
