"""Gatekeeper routes mounted under ``/api/v1/`` (T-002 §7).

Caretaker assignments are nested under their building (the addressable, scoped
resource), matching the project's no-trailing-slash path convention
(``04_coding_conventions.md`` §1):

- ``/api/v1/buildings/{building_id}/caretakers`` — list (GET) / assign (POST)
- ``/api/v1/buildings/{building_id}/caretakers/{assignment_id}`` — revoke (DELETE)
"""

from __future__ import annotations

from django.urls import path

from .views import BuildingCaretakerDetailView, BuildingCaretakersView

app_name = "gatekeeper"

urlpatterns = [
    path(
        "buildings/<int:building_id>/caretakers",
        BuildingCaretakersView.as_view(),
        name="building-caretakers",
    ),
    path(
        "buildings/<int:building_id>/caretakers/<int:assignment_id>",
        BuildingCaretakerDetailView.as_view(),
        name="building-caretaker-detail",
    ),
]
