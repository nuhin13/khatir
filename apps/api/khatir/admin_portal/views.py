"""Admin auth endpoints — EPIC-11.T-003.

Mounted under ``/admin/api/auth/`` (see ``urls.py`` + ``config/urls.py``):

* ``POST login``      — public; verify password, return a token or an
  ``mfa_required`` challenge.
* ``POST verify-mfa`` — public; exchange a challenge + TOTP code for a token.
* ``POST logout``     — admin; revoke the caller's access token.
* ``GET  me``         — admin; the authenticated staff account.

Views only validate (serializer), call a service, and serialize the result.
Business logic, token issuance, and audit live in ``services.py`` /
``auth_tokens.py``; typed service exceptions become the standard error envelope.
"""

from __future__ import annotations

from typing import cast

from rest_framework.permissions import AllowAny
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from khatir.core.responses import no_content, success

from .authentication import AdminJWTAuthentication, IsAdminAuthenticated
from .models import AdminUser
from .serializers import (
    AdminLoginSerializer,
    AdminUserSerializer,
    AdminVerifyMfaSerializer,
)
from .services import admin_login, admin_logout, admin_verify_mfa
from .throttling import (
    AdminLoginEmailThrottle,
    AdminLoginIpThrottle,
    AdminMfaIpThrottle,
)


def _client_ip(request: Request) -> str | None:
    return request.META.get("REMOTE_ADDR")


def _bearer_token(request: Request) -> str:
    header = request.META.get("HTTP_AUTHORIZATION", "")
    parts = header.split()
    return parts[1] if len(parts) == 2 else ""


class AdminLoginView(APIView):
    """``POST /admin/api/auth/login`` — password step of the admin login flow."""

    permission_classes = [AllowAny]
    authentication_classes: list[type] = []
    throttle_classes = [AdminLoginEmailThrottle, AdminLoginIpThrottle]

    def post(self, request: Request) -> Response:
        serializer = AdminLoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        result = admin_login(
            email=serializer.validated_data["email"],
            password=serializer.validated_data["password"],
            ip=_client_ip(request),
        )
        return success(_shape(result))


class AdminVerifyMfaView(APIView):
    """``POST /admin/api/auth/verify-mfa`` — TOTP step, issues the admin token."""

    permission_classes = [AllowAny]
    authentication_classes: list[type] = []
    throttle_classes = [AdminMfaIpThrottle]

    def post(self, request: Request) -> Response:
        serializer = AdminVerifyMfaSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        result = admin_verify_mfa(
            mfa_token=serializer.validated_data["mfa_token"],
            code=serializer.validated_data["code"],
            ip=_client_ip(request),
        )
        return success(_shape(result))


class AdminLogoutView(APIView):
    """``POST /admin/api/auth/logout`` — revoke the caller's access token."""

    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsAdminAuthenticated]

    def post(self, request: Request) -> Response:
        admin_logout(
            admin_user=cast(AdminUser, request.admin_user),  # type: ignore[attr-defined]
            token=_bearer_token(request),
            ip=_client_ip(request),
        )
        return no_content()


class AdminMeView(APIView):
    """``GET /admin/api/auth/me`` — the authenticated staff account."""

    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsAdminAuthenticated]

    def get(self, request: Request) -> Response:
        admin_user = cast(AdminUser, request.admin_user)  # type: ignore[attr-defined]
        return success(AdminUserSerializer(admin_user).data)


def _shape(result: dict[str, object]) -> dict[str, object]:
    """Replace the raw ``admin`` model in a service result with its projection."""
    admin = result.get("admin")
    if isinstance(admin, AdminUser):
        result = {**result, "admin": AdminUserSerializer(admin).data}
    return result
