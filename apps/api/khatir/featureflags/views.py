"""Admin feature-flag endpoints — EPIC-13.T-002.

Mounted at ``/admin/api/flags`` (see :mod:`khatir.featureflags.urls`, included
from ``config/urls.py``). All routes require a valid admin Bearer token and the
``platform`` section role (``super`` / ``ops``) — the same gate the platform
dashboard uses (task §2: super+ops).

* ``GET    /admin/api/flags``              — list every flag.
* ``POST   /admin/api/flags``              — create a flag.
* ``GET    /admin/api/flags/{key}``        — retrieve one flag.
* ``PATCH  /admin/api/flags/{key}``        — update description/scope/value_json.
* ``PATCH  /admin/api/flags/{key}/toggle`` — flip ``enabled`` + bust cache + audit.

Views validate + serialize + delegate; toggle/write business logic and the
audit + cache-bust live in :mod:`khatir.featureflags.services`.
"""

from __future__ import annotations

from typing import cast

from rest_framework import mixins, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import BasePermission
from rest_framework.request import Request
from rest_framework.response import Response

from khatir.admin_portal.authentication import (
    AdminJWTAuthentication,
    IsAdminAuthenticated,
)
from khatir.admin_portal.models import AdminUser
from khatir.admin_portal.permissions import SECTION_ROLES, AdminSection

from .models import FeatureFlag
from .serializers import FeatureFlagSerializer
from .services import record_flag_write, toggle_flag


def _client_ip(request: Request) -> str | None:
    return request.META.get("REMOTE_ADDR")


class IsPlatformAdmin(BasePermission):
    """Gate flag endpoints on the ``platform`` section roles (super / ops).

    Reads the role off the ``AdminUser`` loaded by ``AdminJWTAuthentication``,
    mirroring the platform dashboard so authz stays consistent across the
    admin portal. ``super`` is always inside the platform section set.
    """

    def has_permission(self, request: Request, view: object) -> bool:
        admin_user = getattr(request, "admin_user", None)
        if not isinstance(admin_user, AdminUser) or admin_user.disabled:
            return False
        return admin_user.role in SECTION_ROLES[AdminSection.PLATFORM]


class FeatureFlagViewSet(
    mixins.ListModelMixin,
    mixins.CreateModelMixin,
    mixins.RetrieveModelMixin,
    mixins.UpdateModelMixin,
    viewsets.GenericViewSet,
):
    """CRUD + toggle for feature flags (super/ops only)."""

    queryset = FeatureFlag.objects.all()
    serializer_class = FeatureFlagSerializer
    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsAdminAuthenticated, IsPlatformAdmin]
    lookup_field = "key"
    lookup_value_regex = "[^/]+"

    def perform_create(self, serializer: FeatureFlagSerializer) -> None:
        admin_user = cast(AdminUser, self.request.admin_user)  # type: ignore[attr-defined]
        flag = serializer.save(updated_by=admin_user)
        record_flag_write(
            flag=flag,
            admin_user=admin_user,
            action="feature_flag.create",
            before=None,
            after={
                "key": flag.key,
                "scope": flag.scope,
                "enabled": flag.enabled,
            },
            ip=_client_ip(self.request),
        )

    def perform_update(self, serializer: FeatureFlagSerializer) -> None:
        admin_user = cast(AdminUser, self.request.admin_user)  # type: ignore[attr-defined]
        before = {
            "description": serializer.instance.description,
            "scope": serializer.instance.scope,
            "value_json": serializer.instance.value_json,
        }
        flag = serializer.save()
        record_flag_write(
            flag=flag,
            admin_user=admin_user,
            action="feature_flag.update",
            before=before,
            after={
                "description": flag.description,
                "scope": flag.scope,
                "value_json": flag.value_json,
            },
            ip=_client_ip(self.request),
        )

    @action(detail=True, methods=["patch"], url_path="toggle")
    def toggle(self, request: Request, key: str | None = None) -> Response:
        """Flip ``enabled`` for the flag, record the actor, and bust the cache."""
        flag = self.get_object()
        admin_user = cast(AdminUser, request.admin_user)  # type: ignore[attr-defined]
        flag = toggle_flag(
            flag=flag,
            admin_user=admin_user,
            ip=_client_ip(request),
        )
        return Response(self.get_serializer(flag).data)
