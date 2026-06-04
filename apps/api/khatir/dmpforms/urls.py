"""DMP form routes mounted under ``/api/v1/`` (T-005 §7).

- ``POST /api/v1/tenants/{id}/dmpform/pdf`` — generate a DMP PDF for a tenant.
- ``GET  /api/v1/dmpforms/{id}``           — retrieve a generated record.

No trailing slashes, matching the path convention in
``04_coding_conventions.md`` §1.
"""

from __future__ import annotations

from django.urls import path

from .views import DmpFormRecordDetailView, DmpPdfGenerateView

app_name = "dmpforms"

urlpatterns = [
    path(
        "tenants/<int:tenant_id>/dmpform/pdf",
        DmpPdfGenerateView.as_view(),
        name="dmp-pdf-generate",
    ),
    path(
        "dmpforms/<int:record_id>",
        DmpFormRecordDetailView.as_view(),
        name="dmp-record-detail",
    ),
]
