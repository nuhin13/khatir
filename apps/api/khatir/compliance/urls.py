"""Admin compliance routes — EPIC-16.T-003.

Mounted at ``/admin/api/`` from ``config/urls.py`` (alongside the rest of the
admin-portal application API). Exposes the read-only consent log:

* ``GET /admin/api/consent-records`` — list / filter consent records.

This module is shared by EPIC-16 backend tasks: append new resource routes
below (keep additions additive — never reorder/remove).
"""

from django.urls import path

from .data_request_views import DataRequestListView, DataRequestProcessView
from .views import (
    AdminAuditEntryListView,
    ConsentRecordListView,
    VerificationLogListView,
)

app_name = "compliance"

urlpatterns = [
    path(
        "consent-records",
        ConsentRecordListView.as_view(),
        name="consent-records",
    ),
    path(
        "audit-log",
        AdminAuditEntryListView.as_view(),
        name="audit-log",
    ),
    path(
        "data-requests",
        DataRequestListView.as_view(),
        name="data-requests",
    ),
    path(
        "data-requests/<int:request_id>/process",
        DataRequestProcessView.as_view(),
        name="data-request-process",
    ),
    path(
        "verification-logs",
        VerificationLogListView.as_view(),
        name="verification-logs",
    ),
]
