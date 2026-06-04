"""Leases routes mounted under ``/api/v1/`` (T-003 §7).

Leases are a top-level resource at ``/api/v1/leases`` (no trailing slash,
matching the project's path convention in ``04_coding_conventions.md`` §1).
Lifecycle transitions are router ``@action`` routes on the lease viewset:
``/api/v1/leases/{id}/activate`` and ``/api/v1/leases/{id}/terminate``.
"""

from __future__ import annotations

from rest_framework.routers import DefaultRouter

from .views import LeaseViewSet

app_name = "leases"

router = DefaultRouter(trailing_slash=False)
router.register("leases", LeaseViewSet, basename="lease")

urlpatterns = [
    *router.urls,
]
