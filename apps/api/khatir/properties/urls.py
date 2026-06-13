"""Properties routes mounted under ``/api/v1/`` (T-003 §7, T-004 §7).

Buildings are a top-level resource at ``/api/v1/buildings`` (no trailing slash,
matching the project's path convention in ``04_coding_conventions.md`` §1).
Units live under their building for listing/creation
(``/api/v1/buildings/{id}/units`` and ``…/units/generate``, exposed as router
``@action`` routes on the building viewset) and as a top-level resource for
single-unit detail/update/delete at ``/api/v1/units/{id}``.
"""

from __future__ import annotations

from django.urls import path
from rest_framework.routers import DefaultRouter

from .views import BuildingViewSet, PortfolioView, UnitViewSet

app_name = "properties"

router = DefaultRouter(trailing_slash=False)
router.register("buildings", BuildingViewSet, basename="building")
router.register("units", UnitViewSet, basename="unit")

urlpatterns = [
    path("portfolio", PortfolioView.as_view(), name="portfolio"),
    *router.urls,
]
