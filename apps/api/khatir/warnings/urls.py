"""Warnings routes mounted under ``/api/v1/`` (T-002 §7).

Warnings live under their lease at ``/api/v1/leases/{id}/warnings`` (no trailing
slash, matching ``04_coding_conventions.md`` §1) — a single view serving both
the list (``GET``) and issue (``POST``) verbs.
"""

from __future__ import annotations

from django.urls import path

from .views import LeaseWarningsView

app_name = "warnings"

urlpatterns = [
    path(
        "leases/<int:lease_pk>/warnings",
        LeaseWarningsView.as_view(),
        name="lease-warnings",
    ),
]
