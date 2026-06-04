"""Admin compliance routes — EPIC-16.T-003.

Mounted at ``/admin/api/`` from ``config/urls.py`` (alongside the rest of the
admin-portal application API). Exposes the read-only consent log:

* ``GET /admin/api/consent-records`` — list / filter consent records.

This module is shared by EPIC-16 backend tasks: append new resource routes
below (keep additions additive — never reorder/remove).
"""

from django.urls import path

from .views import AdminAuditEntryListView, ConsentRecordListView

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
]
