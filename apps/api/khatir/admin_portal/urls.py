"""Admin-portal auth routes — EPIC-11.T-003.

Mounted at ``/admin/api/auth/`` from ``config/urls.py``. Kebab-case resource
paths per ``04_coding_conventions.md`` §1. login + verify-mfa are public (no
admin token exists yet); logout + me require a valid admin Bearer token.
"""

from django.urls import path

from .views import (
    AdminLoginView,
    AdminLogoutView,
    AdminMeView,
    AdminVerifyMfaView,
)

app_name = "admin_portal"

urlpatterns = [
    path("login", AdminLoginView.as_view(), name="login"),
    path("verify-mfa", AdminVerifyMfaView.as_view(), name="verify-mfa"),
    path("logout", AdminLogoutView.as_view(), name="logout"),
    path("me", AdminMeView.as_view(), name="me"),
]
