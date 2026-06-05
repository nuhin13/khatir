"""History-sharing routes mounted under ``/api/v1/`` (EPIC-24).

Tenant-initiated shares live under the caller's own ``me/`` namespace —
``POST /api/v1/me/history-shares`` — emphasising that only the tenant
(``request.user``) ever originates a share. No landlord-initiated lookup route
exists, by design.

This module is shared by EPIC-24 backend tasks: append new resource routes
below (keep additions additive — never reorder/remove).
"""

from __future__ import annotations

from django.urls import path

from .views import HistoryShareCreateView, HistoryShareRecipientView

app_name = "historyshare"

urlpatterns = [
    path(
        "me/history-shares",
        HistoryShareCreateView.as_view(),
        name="history-share-create",
    ),
    path(
        "history-shares/<str:token>",
        HistoryShareRecipientView.as_view(),
        name="history-share-recipient",
    ),
]
