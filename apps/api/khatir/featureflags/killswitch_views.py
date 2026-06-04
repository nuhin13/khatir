"""Admin kill-switch endpoints — EPIC-13.T-003.

The platform ships 5 named kill-switches (seeded as ``scope=global`` feature
flags in T-004): ``warnings_feature``, ``reviews_feature``,
``history_flags_feature``, ``free_text_feature``, and ``master_kill_switch``.
A kill-switch is "live" while its backing :class:`FeatureFlag.enabled` is
``True``; throwing the switch flips ``enabled`` and KILLS (or restores) the
feature, busting the public-config cache for instant propagation (<60s budget).

Mounted at ``/admin/api/`` from ``config/urls.py``:

* ``GET  /admin/api/killswitches``              — list the 5 named switches.
* ``POST /admin/api/killswitches/{key}/toggle`` — flip a switch.

Both routes are **super only** (task §2). The toggle additionally requires a
**fresh TOTP re-confirmation** — even inside an active admin session — plus a
mandatory ``reason`` and an optional ``lawyer_reference`` (task §15: intentional
friction). Each toggle records an immutable :class:`KillSwitchEvent`.

Views validate + serialize + delegate; the MFA re-confirm, event write, flag
flip, and cache bust live in :mod:`khatir.featureflags.services`.
"""

from __future__ import annotations

from typing import cast

from rest_framework import serializers, status
from rest_framework.permissions import BasePermission
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from khatir.admin_portal.authentication import (
    AdminJWTAuthentication,
    IsAdminAuthenticated,
)
from khatir.admin_portal.models import AdminUser
from khatir.core.enums import AdminRole

from .serializers import FeatureFlagSerializer
from .services import (
    KILL_SWITCH_KEYS,
    KillSwitchMFAError,
    get_kill_switches,
    toggle_kill_switch,
)


def _client_ip(request: Request) -> str | None:
    return request.META.get("REMOTE_ADDR")


class IsSuperAdmin(BasePermission):
    """Gate kill-switch endpoints on the ``super`` admin role only (task §2)."""

    def has_permission(self, request: Request, view: object) -> bool:
        admin_user = getattr(request, "admin_user", None)
        if not isinstance(admin_user, AdminUser) or admin_user.disabled:
            return False
        return admin_user.role == AdminRole.SUPER


class KillSwitchToggleSerializer(serializers.Serializer):
    """Validate the body of a kill-switch toggle request.

    ``mfa_code`` is the fresh TOTP re-confirmation; ``reason`` is mandatory for
    audit compliance; ``lawyer_reference`` is an optional legal/ticket ref.
    """

    mfa_code = serializers.CharField(max_length=16, trim_whitespace=True)
    reason = serializers.CharField(max_length=2000, trim_whitespace=True)
    lawyer_reference = serializers.CharField(
        max_length=255, required=False, allow_blank=True, default="",
        trim_whitespace=True,
    )


class KillSwitchListView(APIView):
    """``GET /admin/api/killswitches`` — list the 5 named kill-switches (super)."""

    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsAdminAuthenticated, IsSuperAdmin]

    def get(self, request: Request) -> Response:
        switches = get_kill_switches()
        return Response(FeatureFlagSerializer(switches, many=True).data)


class KillSwitchToggleView(APIView):
    """``POST /admin/api/killswitches/{key}/toggle`` — flip a switch (super)."""

    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsAdminAuthenticated, IsSuperAdmin]

    def post(self, request: Request, key: str) -> Response:
        if key not in KILL_SWITCH_KEYS:
            return Response(
                {"detail": f"'{key}' is not a recognised kill-switch."},
                status=status.HTTP_404_NOT_FOUND,
            )

        body = KillSwitchToggleSerializer(data=request.data)
        body.is_valid(raise_exception=True)
        admin_user = cast(AdminUser, request.admin_user)  # type: ignore[attr-defined]

        try:
            flag = toggle_kill_switch(
                key=key,
                admin_user=admin_user,
                mfa_code=body.validated_data["mfa_code"],
                reason=body.validated_data["reason"],
                lawyer_reference=body.validated_data.get("lawyer_reference", ""),
                ip=_client_ip(request),
            )
        except KillSwitchMFAError as exc:
            return Response(
                {"detail": str(exc)}, status=status.HTTP_403_FORBIDDEN
            )

        return Response(FeatureFlagSerializer(flag).data)
