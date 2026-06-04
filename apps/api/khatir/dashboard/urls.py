"""Dashboard route mounted under ``/api/v1/`` (T-002 §7).

A single read endpoint at ``/api/v1/dashboard`` (no trailing slash, per
``04_coding_conventions.md`` §1).
"""

from __future__ import annotations

from django.urls import path

from .views import DashboardView

app_name = "dashboard"

urlpatterns = [
    path("dashboard", DashboardView.as_view(), name="dashboard"),
]
