"""Auth endpoints for OTP sign-in + JWT lifecycle (T-005 §3, T-006 §3).

Public ``APIView``s under ``/api/v1/auth/``:

* ``POST request-otp`` — validate phone, dispatch a code (cooldown-aware).
* ``POST verify-otp``  — validate phone + code, return ``{access, refresh, user}``.
* ``POST refresh``     — exchange a refresh token for a new access token.
* ``POST logout``      — blacklist the supplied refresh token (Bearer required).
* ``GET  me``          — the authenticated user (Bearer required).

Views only: validate (serializer), call a service, serialize the result. Business
logic and error-raising live in ``services.py`` / ``auth_tokens.py``; typed
service exceptions become the standard error envelope via the core handler.
"""

from __future__ import annotations

from typing import cast

from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework_simplejwt.tokens import RefreshToken

from khatir.core.exceptions import AuthInvalidError
from khatir.core.responses import no_content, success

from .models import User
from .serializers import (
    RefreshSerializer,
    RequestOtpSerializer,
    UserSerializer,
    VerifyOtpSerializer,
)
from .services import request_otp, verify_otp_and_issue_tokens
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
    """``POST /api/v1/auth/verify-otp`` — verify an OTP and issue a JWT pair.

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

        user, tokens = verify_otp_and_issue_tokens(phone, code)

        return success(
            {
                "access": tokens["access"],
                "refresh": tokens["refresh"],
                "user": UserSerializer(user).data,
            }
        )


class RefreshView(APIView):
    """``POST /api/v1/auth/refresh`` — exchange a refresh token for an access token.

    With refresh rotation on, a new refresh token is also returned and the old
    one is blacklisted, so a leaked refresh token has a short useful life.
    """

    permission_classes = [AllowAny]
    authentication_classes: list[type] = []

    def post(self, request: Request) -> Response:
        serializer = RefreshSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            refresh = RefreshToken(serializer.validated_data["refresh"])
        except TokenError as exc:
            raise AuthInvalidError("The refresh token is invalid or expired.") from exc

        data = {"access": str(refresh.access_token)}
        # Rotation hands back a fresh refresh token and blacklists the old one.
        data["refresh"] = str(refresh)
        return success(data)


class LogoutView(APIView):
    """``POST /api/v1/auth/logout`` — blacklist the caller's refresh token."""

    permission_classes = [IsAuthenticated]

    def post(self, request: Request) -> Response:
        serializer = RefreshSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            RefreshToken(serializer.validated_data["refresh"]).blacklist()
        except TokenError as exc:
            raise AuthInvalidError("The refresh token is invalid or expired.") from exc

        return no_content()


class MeView(APIView):
    """``GET /api/v1/auth/me`` — the authenticated user for session bootstrap."""

    permission_classes = [IsAuthenticated]

    def get(self, request: Request) -> Response:
        # IsAuthenticated guarantees a real User (never AnonymousUser) here.
        return success(UserSerializer(cast(User, request.user)).data)
