"""Reviews domain models — EPIC-21 (mutual, private, consent-gated reviews).

A ``Review`` is a **private** rating + comment one lease party leaves about the
other. It is **private by construction**:

- It is always tied to a single ``Lease`` (the relationship that legitimises it).
  There is no field, index, or relation that lets reviews be aggregated across
  leases or looked up by person. A searchable public reputation database is
  illegal (Cyber Security Ordinance 2025), so the schema makes one impossible.
- ``visibility`` defaults to ``PRIVATE``. The only built-in path to the reviewee
  seeing a review is the **double-blind reveal**: a review about you becomes
  visible to you only after BOTH parties have submitted. Any visibility beyond
  the reviewer↔reviewee pair requires an explicit ``ConsentRecord``
  (``consent_record`` FK), never a flag on the row alone.

Reveal logic lives in :mod:`khatir.reviews.reveal`; the kill-switch
(``reviews_feature``) and relationship gating are enforced at the endpoint layer
(T-002), not here.
"""

from __future__ import annotations

from django.conf import settings
from django.db import models

from khatir.core.models import SoftDeleteModel

from .enums import ReviewVisibility


class Review(SoftDeleteModel):
    """A private review one lease party leaves about the other."""

    lease = models.ForeignKey(
        "leases.Lease",
        on_delete=models.CASCADE,
        related_name="reviews",
        help_text="The lease relationship this review is tied to. A review only "
        "exists in the context of one lease — never aggregated across leases.",
    )
    reviewer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="reviews_authored",
        help_text="Who wrote the review.",
    )
    reviewee = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="reviews_received",
        help_text="Who the review is about.",
    )
    rating = models.PositiveSmallIntegerField(
        help_text="Rating from 1 to 5 (inclusive).",
    )
    comment = models.TextField(
        blank=True,
        default="",
        help_text="Free-text comment. May be empty.",
    )
    visibility = models.CharField(
        max_length=16,
        choices=ReviewVisibility.choices,
        default=ReviewVisibility.PRIVATE,
        help_text="private (default) / consented. Anything beyond private "
        "requires a logged ConsentRecord.",
    )
    consent_record = models.ForeignKey(
        "compliance.ConsentRecord",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        default=None,
        related_name="reviews",
        help_text="The logged consent that authorises visibility beyond the "
        "reviewer↔reviewee pair. Null for the default private/double-blind case.",
    )
    revealed_at = models.DateTimeField(
        null=True,
        blank=True,
        default=None,
        help_text="UTC timestamp when this review was revealed to the reviewee "
        "(set once the double-blind condition is met or consent is granted).",
    )

    class Meta:
        ordering = ("-created_at",)
        constraints = [
            models.UniqueConstraint(
                fields=["lease", "reviewer"],
                name="uniq_review_per_lease_per_reviewer",
            ),
            models.CheckConstraint(
                condition=models.Q(rating__gte=1) & models.Q(rating__lte=5),
                name="review_rating_between_1_and_5",
            ),
        ]
        indexes = [
            # Scoped to a single lease + the two parties only. There is
            # deliberately NO index that supports "all reviews about person X"
            # across leases — that would enable a public reputation lookup.
            models.Index(fields=["lease", "reviewer"]),
            models.Index(fields=["lease", "reviewee"]),
        ]

    def __str__(self) -> str:
        return (
            f"Review #{self.pk} · lease {self.lease_id} · "
            f"{self.reviewer_id}→{self.reviewee_id} ({self.rating}★)"
        )
