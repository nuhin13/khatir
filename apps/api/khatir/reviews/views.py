"""Reviews API — EPIC-21.T-002 (kill-switch + relationship + reveal gated).

Two endpoints, both authenticated and self/relationship-scoped:

- ``POST /api/v1/leases/{id}/reviews`` — submit a review about your lease
  counterpart. Gated by the ``reviews_feature`` kill-switch (off → 403), then
  the lease-party check (non-party → 403). One review per party per lease.
- ``GET /api/v1/me/reviews`` — the reviews **about you**, reveal-filtered. A
  counterpart review you have not unlocked (double-blind) is returned masked
  (id + pending flag only), never with its rating/comment.

There is deliberately NO endpoint to look up reviews about another person, nor
any public/aggregate listing — that is the illegal public-reputation feature
the epic forbids (task §15).
"""

from __future__ import annotations

from typing import cast

from django.shortcuts import get_object_or_404
from rest_framework import status as http_status
from rest_framework.permissions import BasePermission
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from khatir.accounts.models import User
from khatir.core.permissions import IsAuthenticated
from khatir.core.responses import created, success
from khatir.leases.models import Lease

from .reveal import can_view
from .serializers import (
    PendingReviewSerializer,
    ReviewSerializer,
    ReviewSubmitSerializer,
)
from .services import (
    AlreadyReviewed,
    NotALeaseParty,
    reviews_about,
    reviews_feature_enabled,
    submit_review,
)


class ReviewsFeatureEnabled(BasePermission):
    """Deny (403) every request while the ``reviews_feature`` kill-switch is off.

    Evaluated before any relationship check so a killed feature is uniformly
    invisible — the kill-switch comes first (task §2).
    """

    message = "The reviews feature is currently unavailable."

    def has_permission(self, request: Request, view: object) -> bool:
        return reviews_feature_enabled()


class LeaseReviewSubmitView(APIView):
    """``POST /api/v1/leases/{id}/reviews`` — submit a review about the counterpart."""

    permission_classes = [IsAuthenticated & ReviewsFeatureEnabled]

    def post(self, request: Request, lease_id: int) -> Response:
        lease = get_object_or_404(Lease.objects.all(), pk=lease_id)
        serializer = ReviewSubmitSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            review = submit_review(
                actor=cast(User, request.user),
                lease=lease,
                **serializer.validated_data,
            )
        except NotALeaseParty as exc:
            return Response(
                {"detail": str(exc)}, status=http_status.HTTP_403_FORBIDDEN
            )
        except AlreadyReviewed as exc:
            return Response(
                {"detail": str(exc)}, status=http_status.HTTP_409_CONFLICT
            )
        return created(ReviewSerializer(review).data)


class MyReviewsView(APIView):
    """``GET /api/v1/me/reviews`` — reviews about the authenticated user.

    Each review is shown in full only once :func:`can_view` allows it (the
    double-blind/consent reveal); otherwise it is masked to a pending stub so the
    hidden rating/comment never leaks.
    """

    permission_classes = [IsAuthenticated & ReviewsFeatureEnabled]

    def get(self, request: Request) -> Response:
        viewer = cast(User, request.user)
        revealed = []
        pending = []
        for review in reviews_about(viewer):
            if can_view(review, viewer_id=viewer.pk):
                revealed.append(ReviewSerializer(review).data)
            else:
                pending.append(PendingReviewSerializer(review).data)
        return success({"revealed": revealed, "pending": pending})
