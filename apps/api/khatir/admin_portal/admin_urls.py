"""Admin-portal application routes — EPIC-11.T-005.

Mounted at ``/admin/api/`` from ``config/urls.py`` (the auth sub-tree lives at
``/admin/api/auth/`` via :mod:`khatir.admin_portal.urls`). These routes require
a valid admin Bearer token; the dashboard additionally requires a ``platform``
section role (super/ops).

This module is shared: other admin-portal tasks append their resource routes
below the dashboard entry (keep additions additive — never reorder/remove).
"""

from django.urls import path

from khatir.ai_providers.admin_views import (
    AIProviderDetailView,
    AIProviderListCreateView,
    AIProviderTestConnectionView,
    AIUsageView,
)

from .audit_views import AuditLogView
from .dashboard_views import PlatformDashboardView
from .pricing_views import (
    PricingTierEditView,
    PricingTierListView,
    PricingTierPreviewView,
)
from .refund_views import RefundProcessView, RefundQueueView
from .user_views import (
    UserDetailView,
    UserReactivateView,
    UserSearchView,
    UserSuspendView,
    UserUpgradeSubscriptionView,
)

app_name = "admin_portal_app"

urlpatterns = [
    path("dashboard", PlatformDashboardView.as_view(), name="dashboard"),
    # EPIC-11.T-011 — compliance audit-log viewer (read-only, paginated).
    path("audit-log", AuditLogView.as_view(), name="audit-log"),
    # EPIC-12.T-003 — user search + detail + actions.
    path("users", UserSearchView.as_view(), name="users-search"),
    path("users/<int:user_id>", UserDetailView.as_view(), name="users-detail"),
    path(
        "users/<int:user_id>/suspend",
        UserSuspendView.as_view(),
        name="users-suspend",
    ),
    path(
        "users/<int:user_id>/reactivate",
        UserReactivateView.as_view(),
        name="users-reactivate",
    ),
    path(
        "users/<int:user_id>/upgrade-subscription",
        UserUpgradeSubscriptionView.as_view(),
        name="users-upgrade-subscription",
    ),
    # EPIC-12.T-001 — pricing tier list + impact preview + edit.
    path("pricing/tiers", PricingTierListView.as_view(), name="pricing-tiers"),
    path(
        "pricing/tiers/<str:key>",
        PricingTierEditView.as_view(),
        name="pricing-tier-edit",
    ),
    path(
        "pricing/tiers/<str:key>/preview",
        PricingTierPreviewView.as_view(),
        name="pricing-tier-preview",
    ),
    # EPIC-12.T-004 — finance refund queue + process.
    path("billing/refunds", RefundQueueView.as_view(), name="refunds-queue"),
    path(
        "billing/refunds/<int:intent_id>/process",
        RefundProcessView.as_view(),
        name="refunds-process",
    ),
    # EPIC-14.T-009 — AI provider CRUD + test-connection + usage.
    path(
        "ai-providers",
        AIProviderListCreateView.as_view(),
        name="ai-providers",
    ),
    path(
        "ai-providers/<int:provider_id>",
        AIProviderDetailView.as_view(),
        name="ai-providers-detail",
    ),
    path(
        "ai-providers/<int:provider_id>/test-connection",
        AIProviderTestConnectionView.as_view(),
        name="ai-providers-test-connection",
    ),
    path("ai-usage", AIUsageView.as_view(), name="ai-usage"),
]
