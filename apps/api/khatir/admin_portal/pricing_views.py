"""Admin-portal pricing-tier endpoints — EPIC-12.T-001.

Mounted under ``/admin/api/`` (see ``admin_urls.py`` + ``config/urls.py``):

* ``GET   pricing/tiers``               — list every tier (active + inactive).
* ``POST  pricing/tiers/{key}/preview`` — read-only impact of proposed changes.
* ``PATCH pricing/tiers/{key}``         — apply changes (reason req.), audited.

Authz is the dedicated admin JWT realm (``AdminJWTAuthentication`` →
``request.admin_user``), gated on the ``pricing`` section: **finance** and
**super** only. The list is read-only and shares the same gate (the section has
no read-only role). Views only validate and serialize; all logic, impact math,
audit, and cache-busting live in :mod:`.pricing_services`.
"""

from __future__ import annotations

from typing import cast

from rest_framework.permissions import BasePermission
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from khatir.core.responses import success

from .authentication import AdminJWTAuthentication, IsAdminAuthenticated
from .models import AdminUser
from .permissions import FINANCE, SUPER
from .pricing_serializers import (
    PricingTierAdminSerializer,
    TierEditSerializer,
    TierPreviewSerializer,
)
from .pricing_services import compute_impact, edit_tier, get_tier_or_404, list_tiers

#: Roles allowed in the pricing section — finance and super only.
_PRICING_ROLES: frozenset[str] = frozenset({SUPER, FINANCE})


def _client_ip(request: Request) -> str | None:
    return request.META.get("REMOTE_ADDR")


class IsPricingAdmin(BasePermission):
    """Allow only a non-disabled admin whose role may manage pricing."""

    def has_permission(self, request: Request, view: APIView) -> bool:
        admin_user = getattr(request, "admin_user", None)
        if not isinstance(admin_user, AdminUser) or admin_user.disabled:
            return False
        return admin_user.role in _PRICING_ROLES


class PricingTierListView(APIView):
    """``GET /admin/api/pricing/tiers`` — every tier in plan-picker order."""

    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsAdminAuthenticated, IsPricingAdmin]

    def get(self, request: Request) -> Response:
        tiers = list_tiers()
        return success(PricingTierAdminSerializer(tiers, many=True).data)


class PricingTierPreviewView(APIView):
    """``POST /admin/api/pricing/tiers/{key}/preview`` — read-only impact calc."""

    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsAdminAuthenticated, IsPricingAdmin]

    def post(self, request: Request, key: str) -> Response:
        tier = get_tier_or_404(key)
        serializer = TierPreviewSerializer(data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        impact = compute_impact(tier, dict(serializer.validated_data))
        return success(impact)


class PricingTierEditView(APIView):
    """``PATCH /admin/api/pricing/tiers/{key}`` — apply changes (reason req.)."""

    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsAdminAuthenticated, IsPricingAdmin]

    def patch(self, request: Request, key: str) -> Response:
        serializer = TierEditSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        changes = dict(serializer.validated_data)
        reason = changes.pop("reason")
        tier = edit_tier(
            key=key,
            admin_user=cast(AdminUser, request.admin_user),  # type: ignore[attr-defined]
            changes=changes,
            reason=reason,
            ip=_client_ip(request),
        )
        return success(PricingTierAdminSerializer(tier).data)
