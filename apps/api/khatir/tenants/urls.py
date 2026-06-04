"""Tenants routes mounted under ``/api/v1/`` (T-007 §7).

Tenants are a top-level resource at ``/api/v1/tenants`` (no trailing slash,
matching ``04_coding_conventions.md`` §1). Listing the tenants of a unit lives
under that unit at ``/api/v1/units/{id}/tenants`` — a read-only view alongside
the properties domain's unit routes.
"""

from __future__ import annotations

from django.urls import path
from rest_framework.routers import DefaultRouter

from .views import TenantViewSet, UnitTenantsView

app_name = "tenants"

router = DefaultRouter(trailing_slash=False)
router.register("tenants", TenantViewSet, basename="tenant")

urlpatterns = [
    path(
        "units/<int:unit_pk>/tenants",
        UnitTenantsView.as_view(),
        name="unit-tenants",
    ),
    *router.urls,
]
