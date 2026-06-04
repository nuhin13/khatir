"""Admin-portal user-management endpoints — EPIC-12.T-003.

Mounted under ``/admin/api/`` (see ``admin_urls.py`` + ``config/urls.py``):

* ``GET  users``                      — search by phone/name/ID/masked-NID.
* ``GET  users/{id}``                 — profile + subscription + usage + audit.
* ``POST users/{id}/suspend``         — deactivate + blacklist JWTs (reason req.).
* ``POST users/{id}/reactivate``      — re-enable.
* ``POST users/{id}/upgrade-subscription`` — manual tier override.

Authz is the dedicated admin JWT realm (``AdminJWTAuthentication`` →
``request.admin_user``), gated on the ``users`` section. ``support`` is
**read-only**: it may search and view, but the three write actions require
``ops`` / ``super`` (the ``IsUsersWriteAdmin`` gate). Views only validate and
serialize; all logic + audit lives in :mod:`.user_services`.
"""

from __future__ import annotations

from typing import cast

from rest_framework.permissions import BasePermission
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from khatir.core.pagination import StandardPageNumberPagination
from khatir.core.responses import success

from .authentication import AdminJWTAuthentication, IsAdminAuthenticated
from .models import AdminUser
from .permissions import OPS, SECTION_ROLES, SUPER, AdminSection
from .user_serializers import (
    AdminAuditTrailSerializer,
    AdminReactivateUserSerializer,
    AdminSubscriptionSerializer,
    AdminSuspendUserSerializer,
    AdminUpgradeSubscriptionSerializer,
    AdminUserListSerializer,
)
from .user_services import (
    get_user_or_404,
    reactivate_user,
    search_users,
    suspend_user,
    upgrade_subscription,
    user_detail,
)

#: Roles that may *read* the users section (support is read-only).
_USERS_READ_ROLES = SECTION_ROLES[AdminSection.USERS]
#: Roles that may *write* in the users section (support excluded).
_USERS_WRITE_ROLES = frozenset({SUPER, OPS})


def _client_ip(request: Request) -> str | None:
    return request.META.get("REMOTE_ADDR")


class _UsersSectionPermission(BasePermission):
    """Base gate: a non-disabled admin whose role is in ``allowed_roles``."""

    allowed_roles: frozenset[str] = frozenset()

    def has_permission(self, request: Request, view: APIView) -> bool:
        admin_user = getattr(request, "admin_user", None)
        if not isinstance(admin_user, AdminUser) or admin_user.disabled:
            return False
        return admin_user.role in self.allowed_roles


class IsUsersReadAdmin(_UsersSectionPermission):
    """Read access to the users section (super / ops / support)."""

    allowed_roles = _USERS_READ_ROLES


class IsUsersWriteAdmin(_UsersSectionPermission):
    """Write access to the users section (super / ops only — support denied)."""

    allowed_roles = _USERS_WRITE_ROLES


class UserSearchView(APIView):
    """``GET /admin/api/users`` — paginated user search."""

    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsAdminAuthenticated, IsUsersReadAdmin]

    def get(self, request: Request) -> Response:
        query = request.query_params.get("q", "")
        queryset = search_users(query)

        paginator = StandardPageNumberPagination()
        page = paginator.paginate_queryset(queryset, request, view=self)
        data = AdminUserListSerializer(page, many=True).data
        return paginator.get_paginated_response(data)


class UserDetailView(APIView):
    """``GET /admin/api/users/{id}`` — full profile + subscription + usage + audit."""

    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsAdminAuthenticated, IsUsersReadAdmin]

    def get(self, request: Request, user_id: int) -> Response:
        user = get_user_or_404(user_id)
        detail = user_detail(user)
        subscription = detail["subscription"]
        return success(
            {
                "user": AdminUserListSerializer(detail["user"]).data,
                "subscription": (
                    AdminSubscriptionSerializer(subscription).data
                    if subscription is not None
                    else None
                ),
                "usage": detail["usage"],
                "audit_trail": AdminAuditTrailSerializer(
                    detail["audit_trail"], many=True
                ).data,
            }
        )


class UserSuspendView(APIView):
    """``POST /admin/api/users/{id}/suspend`` — deactivate + invalidate JWTs."""

    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsAdminAuthenticated, IsUsersWriteAdmin]

    def post(self, request: Request, user_id: int) -> Response:
        serializer = AdminSuspendUserSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = get_user_or_404(user_id)
        user = suspend_user(
            user=user,
            admin_user=cast(AdminUser, request.admin_user),  # type: ignore[attr-defined]
            reason=serializer.validated_data["reason"],
            ip=_client_ip(request),
        )
        return success(AdminUserListSerializer(user).data)


class UserReactivateView(APIView):
    """``POST /admin/api/users/{id}/reactivate`` — re-enable a suspended user."""

    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsAdminAuthenticated, IsUsersWriteAdmin]

    def post(self, request: Request, user_id: int) -> Response:
        serializer = AdminReactivateUserSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = get_user_or_404(user_id)
        user = reactivate_user(
            user=user,
            admin_user=cast(AdminUser, request.admin_user),  # type: ignore[attr-defined]
            reason=serializer.validated_data.get("reason", ""),
            ip=_client_ip(request),
        )
        return success(AdminUserListSerializer(user).data)


class UserUpgradeSubscriptionView(APIView):
    """``POST /admin/api/users/{id}/upgrade-subscription`` — manual tier override."""

    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsAdminAuthenticated, IsUsersWriteAdmin]

    def post(self, request: Request, user_id: int) -> Response:
        serializer = AdminUpgradeSubscriptionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = get_user_or_404(user_id)
        subscription = upgrade_subscription(
            user=user,
            admin_user=cast(AdminUser, request.admin_user),  # type: ignore[attr-defined]
            tier_id=serializer.validated_data["tier_id"],
            billing_cycle=serializer.validated_data.get("billing_cycle", ""),
            reason=serializer.validated_data["reason"],
            ip=_client_ip(request),
        )
        return success(AdminSubscriptionSerializer(subscription).data)
