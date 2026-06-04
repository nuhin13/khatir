"""Admin-portal application routes — EPIC-11.T-005.

Mounted at ``/admin/api/`` from ``config/urls.py`` (the auth sub-tree lives at
``/admin/api/auth/`` via :mod:`khatir.admin_portal.urls`). These routes require
a valid admin Bearer token; the dashboard additionally requires a ``platform``
section role (super/ops).

This module is shared: other admin-portal tasks append their resource routes
below the dashboard entry (keep additions additive — never reorder/remove).
"""

from django.urls import path

from .dashboard_views import PlatformDashboardView

app_name = "admin_portal_app"

urlpatterns = [
    path("dashboard", PlatformDashboardView.as_view(), name="dashboard"),
]
