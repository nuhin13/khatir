"""Rent-collection routes mounted under ``/api/v1/`` (T-003 §7).

Rent requests are a top-level resource at ``/api/v1/rent-requests`` (no trailing
slash, matching ``04_coding_conventions.md`` §1): POST to create, GET to list the
landlord's queue, GET ``/{id}`` for a single request.
"""

from __future__ import annotations

from rest_framework.routers import DefaultRouter

from .views import RentRequestViewSet

app_name = "rent"

router = DefaultRouter(trailing_slash=False)
router.register("rent-requests", RentRequestViewSet, basename="rent-request")

urlpatterns = [*router.urls]
