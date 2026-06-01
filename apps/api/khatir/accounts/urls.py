"""Auth routes mounted under ``/api/v1/auth/`` (T-005 §3, §7).

Kebab-case resource paths per ``04_coding_conventions.md`` §1. Both endpoints
are public (OTP sign-in is the entry point before any token exists).
"""

from django.urls import path

from .views import RequestOtpView, VerifyOtpView

app_name = "accounts"

urlpatterns = [
    path("request-otp", RequestOtpView.as_view(), name="request-otp"),
    path("verify-otp", VerifyOtpView.as_view(), name="verify-otp"),
]
