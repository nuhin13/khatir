"""Reviews routes mounted under ``/api/v1/`` (T-002 §7).

Only two routes exist, by design:

- ``POST /api/v1/leases/{id}/reviews`` — submit (nested under the lease that
  legitimises the review).
- ``GET  /api/v1/me/reviews`` — the reviews about the authenticated user.

There is deliberately NO ``/reviews`` collection, no ``/users/{id}/reviews``,
and no search/aggregate route — a public reputation lookup is the illegal
feature this epic forbids (task §15).
"""

from __future__ import annotations

from django.urls import path

from .views import LeaseReviewSubmitView, MyReviewsView

app_name = "reviews"

urlpatterns = [
    path(
        "leases/<int:lease_id>/reviews",
        LeaseReviewSubmitView.as_view(),
        name="lease-review-submit",
    ),
    path("me/reviews", MyReviewsView.as_view(), name="my-reviews"),
]
