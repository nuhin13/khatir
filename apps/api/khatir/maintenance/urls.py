"""Maintenance routes mounted under ``/api/v1/`` (T-002 §7).

Maintenance requests are a top-level resource at ``/api/v1/maintenance`` (no
trailing slash, matching the project's path convention in
``04_coding_conventions.md`` §1). The resolve transition is a router ``@action``
route on the viewset: ``/api/v1/maintenance/{id}/resolve``.
"""

from __future__ import annotations

from rest_framework.routers import DefaultRouter

from .expense_views import ExpenseViewSet
from .views import MaintenanceRequestViewSet

app_name = "maintenance"

router = DefaultRouter(trailing_slash=False)
router.register("maintenance", MaintenanceRequestViewSet, basename="maintenance")
router.register("expenses", ExpenseViewSet, basename="expense")

urlpatterns = [
    *router.urls,
]
