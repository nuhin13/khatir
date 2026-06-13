"""Tenants routes mounted under ``/api/v1/`` (T-007 §7).

Tenants are a top-level resource at ``/api/v1/tenants`` (no trailing slash,
matching ``04_coding_conventions.md`` §1). Listing the tenants of a unit lives
under that unit at ``/api/v1/units/{id}/tenants`` — a read-only view alongside
the properties domain's unit routes.
"""

from __future__ import annotations

from django.urls import path
from rest_framework.routers import DefaultRouter

from .me_views import (
    MeLeaseView,
    MeMaintenanceView,
    MeReceiptsView,
    MeRentPayView,
    MeRentView,
)
from .views import (
    TenantOcrView,
    TenantViewSet,
    TenantVoiceView,
    UnitTenantsView,
    UsageView,
)

app_name = "tenants"

router = DefaultRouter(trailing_slash=False)
router.register("tenants", TenantViewSet, basename="tenant")

urlpatterns = [
    # Declared before the router so ``tenants/ocr`` / ``tenants/voice`` resolve
    # to their actions rather than the viewset's ``tenants/<pk>`` detail route.
    path("tenants/ocr", TenantOcrView.as_view(), name="tenant-ocr"),
    path("tenants/voice", TenantVoiceView.as_view(), name="tenant-voice"),
    path(
        "units/<int:unit_pk>/tenants",
        UnitTenantsView.as_view(),
        name="unit-tenants",
    ),
    # Free-tier counter consumed by More/plan + EPIC-10 (T-008 §7/§8).
    path("usage", UsageView.as_view(), name="usage"),
    # Tenant self-service surface (EPIC-19 T-002): read-only, gated by
    # IsLinkedTenant, every read scoped through the tenant_account helpers.
    path("me/lease", MeLeaseView.as_view(), name="me-lease"),
    path("me/rent", MeRentView.as_view(), name="me-rent"),
    # In-app payment proof (EPIC-19 T-003): reuses the EPIC-07 PaymentProof
    # pipeline, scoped to the tenant's own rent requests.
    path("me/rent/<int:pk>/pay", MeRentPayView.as_view(), name="me-rent-pay"),
    path("me/receipts", MeReceiptsView.as_view(), name="me-receipts"),
    # In-app maintenance report (EPIC-19 T-004): reuses the EPIC-08
    # create_maintenance_request pipeline, scoped to the tenant's own unit.
    path("me/maintenance", MeMaintenanceView.as_view(), name="me-maintenance"),
    *router.urls,
]
