"""Gatekeeper routes mounted under ``/api/v1/`` (T-002 §7).

Caretaker assignments are nested under their building (the addressable, scoped
resource), matching the project's no-trailing-slash path convention
(``04_coding_conventions.md`` §1):

- ``/api/v1/buildings/{building_id}/caretakers`` — list (GET) / assign (POST)
- ``/api/v1/buildings/{building_id}/caretakers/{assignment_id}`` — revoke (DELETE)

Caretaker-facing endpoints (T-003 §7) are scoped to the acting caretaker (their
actively-assigned buildings), so they are *not* nested under a building id:

- ``/api/v1/caretaker/home`` — today's activity for assigned buildings (GET)
- ``/api/v1/caretaker/visitors`` — pending visitor queue (GET)
- ``/api/v1/caretaker/visitors/{entry_id}/review`` — approve/deny (POST)
"""

from __future__ import annotations

from django.urls import path

from .views import (
    BuildingCaretakerDetailView,
    BuildingCaretakersView,
    CaretakerHomeView,
    CaretakerVisitorQueueView,
    CaretakerVisitorReviewView,
)

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
    path(
        "caretaker/home",
        CaretakerHomeView.as_view(),
        name="caretaker-home",
    ),
    path(
        "caretaker/visitors",
        CaretakerVisitorQueueView.as_view(),
        name="caretaker-visitors",
    ),
    path(
        "caretaker/visitors/<int:entry_id>/review",
        CaretakerVisitorReviewView.as_view(),
        name="caretaker-visitor-review",
    ),
]
