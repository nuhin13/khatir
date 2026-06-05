"""Reviews API serializers — EPIC-21.T-002.

Two read/write shapes only:

- :class:`ReviewSubmitSerializer` validates an inbound submission (``rating`` +
  optional ``comment``). The reviewer, reviewee, and lease are derived
  server-side from the authenticated user and the URL — never trusted from the
  client.
- :class:`ReviewSerializer` is the **reveal-aware** output shape. The
  reviewer↔reviewee body (rating/comment) is only ever populated by the view
  once :func:`khatir.reviews.reveal.can_view` says the viewer may read it; for a
  not-yet-revealed counterpart review the view emits the masked
  :class:`PendingReviewSerializer` instead. There is, by design, no field that
  exposes a person's reviews across leases or any aggregate score.
"""

from __future__ import annotations

from rest_framework import serializers

from .models import Review


class ReviewSubmitSerializer(serializers.Serializer):
    """Inbound payload for ``POST /leases/{id}/reviews``.

    Only the free-text body is client-supplied; identity and relationship are
    resolved server-side. ``comment`` is optional and defaults to empty.
    """

    rating = serializers.IntegerField(min_value=1, max_value=5)
    comment = serializers.CharField(
        required=False,
        allow_blank=True,
        default="",
        trim_whitespace=True,
    )


class ReviewSerializer(serializers.ModelSerializer[Review]):
    """Full (revealed) review shape — used for the viewer's own reviews and for
    counterpart reviews that have passed the double-blind/consent reveal gate."""

    class Meta:
        model = Review
        fields = (
            "id",
            "lease",
            "reviewer",
            "reviewee",
            "rating",
            "comment",
            "visibility",
            "revealed_at",
            "created_at",
        )
        read_only_fields = fields


class PendingReviewSerializer(serializers.ModelSerializer[Review]):
    """Masked shape for a counterpart review that is **not yet revealed**.

    Surfaces only that a review *about the viewer* exists and is pending the
    double-blind condition — never its rating or comment. This lets a client
    prompt "submit yours to unlock theirs" without leaking the hidden content.
    """

    revealed = serializers.SerializerMethodField()

    class Meta:
        model = Review
        fields = ("id", "lease", "reviewee", "revealed", "created_at")
        read_only_fields = fields

    def get_revealed(self, obj: Review) -> bool:  # noqa: PLR6301 - DRF method field
        return False
