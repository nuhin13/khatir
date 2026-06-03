"""Properties routes mounted under ``/api/v1/`` (T-003 §7).

Buildings are a top-level resource at ``/api/v1/buildings`` (no trailing slash,
matching the project's path convention in ``04_coding_conventions.md`` §1).
"""

from __future__ import annotations

from rest_framework.routers import DefaultRouter

from .views import BuildingViewSet

app_name = "properties"

router = DefaultRouter(trailing_slash=False)
router.register("buildings", BuildingViewSet, basename="building")

urlpatterns = router.urls
