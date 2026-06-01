"""Thin auth endpoints for OTP sign-in (T-005 §3).

Two public ``APIView``s under ``/api/v1/auth/``:

* ``POST request-otp`` — validate phone, dispatch a code (cooldown-aware).
* ``POST verify-otp``  — validate phone + code, return the (created-or-fetched)
  ``User``. JWT issuance is T-006; this endpoint deliberately stops at the user.

Views only: validate (serializer), call a service, serialize the result. All
business logic and all error-raising lives in ``services.py``; typed service
exceptions are turned into the standard error envelope by the core handler.
"""

from __future__ import annotations

from rest_framework.permissions import AllowAny
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from khatir.core.responses import success

from .serializers import RequestOtpSerializer, VerifyOtpSerializer
from .services import request_otp, verify_otp_and_get_user
from .throttling import (
    RequestOtpIpThrottle,
    RequestOtpPhoneThrottle,
    VerifyOtpIpThrottle,
    VerifyOtpPhoneThrottle,
)


class RequestOtpView(APIView):
    """``POST /api/v1/auth/request-otp`` — issue an OTP for a phone number.

    Rate-limited per phone and per IP (T-007) above the per-phone resend
    cooldown (T-003); exceeding a limit returns ``429 rate_limited``.
    """

    permission_classes = [AllowAny]
    authentication_classes: list[type] = []
    throttle_classes = [RequestOtpPhoneThrottle, RequestOtpIpThrottle]

    def post(self, request: Request) -> Response:
        serializer = RequestOtpSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        phone = serializer.validated_data["phone"]

        channel = request_otp(phone)

        return success({"sent": True, "channel": channel.value})


class VerifyOtpView(APIView):
    """``POST /api/v1/auth/verify-otp`` — verify an OTP and return the user.

    Tokens (access/refresh) are added in T-006, which wraps this same service.
    Rate-limited per phone and per IP (T-007) above the per-code attempt cap
    (T-003); exceeding a limit returns ``429 rate_limited``.
    """

    permission_classes = [AllowAny]
    authentication_classes: list[type] = []
    throttle_classes = [VerifyOtpPhoneThrottle, VerifyOtpIpThrottle]

    def post(self, request: Request) -> Response:
        serializer = VerifyOtpSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        phone = serializer.validated_data["phone"]
        code = serializer.validated_data["code"]

        user = verify_otp_and_get_user(phone, code)

        return success(
            {
                "user": {
                    "id": str(user.pk),
                    "phone": user.phone,
                    "role": user.role,
                    "name": user.name,
                    "language": user.language,
                }
            }
        )
