"""Verification routes mounted under ``/api/v1/`` (T-004 §7).

Both endpoints hang off an existing tenant:

* ``POST /api/v1/tenants/{id}/verify``       — run EC verification.
* ``GET  /api/v1/tenants/{id}/verification`` — read the last result.

No trailing slash (``04_coding_conventions.md`` §1).
"""

from __future__ import annotations

from django.urls import path

from .views import VerificationView, VerifyView

app_name = "verification"

urlpatterns = [
    path(
        "tenants/<int:tenant_pk>/verify",
        VerifyView.as_view(),
        name="tenant-verify",
    ),
    path(
        "tenants/<int:tenant_pk>/verification",
        VerificationView.as_view(),
        name="tenant-verification",
    ),
]
