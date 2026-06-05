"""Manager owner-link routes mounted under ``/api/v1/`` (EPIC-22 · T-003 §7).

No trailing slash (``04_coding_conventions.md`` §1).
"""

from __future__ import annotations

from django.urls import path

from .views import (
    ManagerDashboardView,
    ManagerOwnersView,
    OwnerLinkConsentView,
)

app_name = "managers"

urlpatterns = [
    path("manager/owners", ManagerOwnersView.as_view(), name="owners"),
    path(
        "manager/owners/<int:link_id>/consent",
        OwnerLinkConsentView.as_view(),
        name="owner-consent",
    ),
    path("manager/dashboard", ManagerDashboardView.as_view(), name="dashboard"),
]
