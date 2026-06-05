"""Lease-document routes mounted under ``/api/v1/`` (EPIC-18 · T-004 §7).

- ``POST  /api/v1/leases/{id}/generate-document`` — AI-draft a lease document.
- ``PATCH /api/v1/lease-documents/{id}``          — edit a draft's clauses.
- ``POST  /api/v1/lease-documents/{id}/pdf``      — render PDF → signed URL.

No trailing slashes, matching the path convention in
``04_coding_conventions.md`` §1.
"""

from __future__ import annotations

from django.urls import path

from .views import (
    GenerateLeaseDocumentView,
    LeaseDocumentEditView,
    LeaseDocumentPdfView,
)

app_name = "leasedocs"

urlpatterns = [
    path(
        "leases/<int:lease_id>/generate-document",
        GenerateLeaseDocumentView.as_view(),
        name="lease-generate-document",
    ),
    path(
        "lease-documents/<int:document_id>",
        LeaseDocumentEditView.as_view(),
        name="lease-document-edit",
    ),
    path(
        "lease-documents/<int:document_id>/pdf",
        LeaseDocumentPdfView.as_view(),
        name="lease-document-pdf",
    ),
]
