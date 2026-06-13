"""Billing routes mounted under ``/api/v1/`` (T-004 §7).

Subscription endpoints live under ``/api/v1/billing`` (no trailing slash, per
``04_coding_conventions.md`` §1): ``GET billing/subscription`` for the current
plan + usage and ``POST billing/subscribe`` to subscribe/upgrade.
"""

from __future__ import annotations

from django.urls import path

from .views import SubscribeView, SubscriptionView

app_name = "billing"

urlpatterns = [
    path(
        "billing/subscription",
        SubscriptionView.as_view(),
        name="subscription",
    ),
    path("billing/subscribe", SubscribeView.as_view(), name="subscribe"),
]
