"""Gov-export routes mounted under ``/api/v1/`` (EPIC-26 T-004 §1).

- ``POST /api/v1/gov-export``      — generate a submission package for a period.
- ``GET  /api/v1/gov-export/{id}`` — fetch a row + a fresh signed download URL.

No trailing slashes, matching the path convention in
``04_coding_conventions.md`` §1.
"""

from __future__ import annotations

from django.urls import path

from .views import GovExportDetailView, GovExportGenerateView

app_name = "govexport"

urlpatterns = [
    path(
        "gov-export",
        GovExportGenerateView.as_view(),
        name="gov-export-generate",
    ),
    path(
        "gov-export/<int:export_id>",
        GovExportDetailView.as_view(),
        name="gov-export-detail",
    ),
]
