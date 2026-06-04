"""Admin AI-provider endpoints — EPIC-14.T-009.

Mounted under ``/admin/api/`` (see ``admin_portal/admin_urls.py``):

* ``GET   ai-providers``                    — list every provider config.
* ``POST  ai-providers``                    — create a provider (DPA-validated).
* ``PATCH ai-providers/{id}``               — edit a provider (DPA-validated).
* ``POST  ai-providers/{id}/test-connection`` — verify creds via the gateway.
* ``GET   ai-usage``                        — aggregated usage from AIUsageLog.

Authz is the dedicated admin JWT realm (``AdminJWTAuthentication`` →
``request.admin_user``), gated on the ``platform`` section: **super** and
**ops** only. Every consequential write is recorded with :func:`admin_audit`;
the API key is encrypted by the serializer and never logged or returned.
"""

from __future__ import annotations

from decimal import Decimal
from typing import cast

from django.db.models import Count, Q, Sum
from django.shortcuts import get_object_or_404
from rest_framework.permissions import BasePermission
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from khatir.admin_portal.audit import admin_audit
from khatir.admin_portal.authentication import (
    AdminJWTAuthentication,
    IsAdminAuthenticated,
)
from khatir.admin_portal.models import AdminUser
from khatir.admin_portal.permissions import OPS, SUPER
from khatir.core.responses import created, success

from .client import AIGatewayError, call_gateway
from .models import AIProvider, AIUsageLog
from .serializers import AIProviderAdminSerializer

#: Roles allowed to manage AI providers — the platform section (super + ops).
_AI_ROLES: frozenset[str] = frozenset({SUPER, OPS})


def _client_ip(request: Request) -> str | None:
    return request.META.get("REMOTE_ADDR")


class IsAIProviderAdmin(BasePermission):
    """Allow only a non-disabled admin whose role may manage AI providers."""

    def has_permission(self, request: Request, view: APIView) -> bool:
        admin_user = getattr(request, "admin_user", None)
        if not isinstance(admin_user, AdminUser) or admin_user.disabled:
            return False
        return admin_user.role in _AI_ROLES


class _BaseAIProviderView(APIView):
    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsAdminAuthenticated, IsAIProviderAdmin]


class AIProviderListCreateView(_BaseAIProviderView):
    """``GET/POST /admin/api/ai-providers`` — list all / create one."""

    def get(self, request: Request) -> Response:
        providers = AIProvider.objects.all()
        return success(AIProviderAdminSerializer(providers, many=True).data)

    def post(self, request: Request) -> Response:
        serializer = AIProviderAdminSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        provider = serializer.save()
        admin_audit(
            admin_user=cast(AdminUser, request.admin_user),  # type: ignore[attr-defined]
            action="ai_provider.create",
            entity=provider,
            after={
                "category": provider.category,
                "provider_key": provider.provider_key,
                "active": provider.active,
            },
            ip=_client_ip(request),
        )
        return created(AIProviderAdminSerializer(provider).data)


class AIProviderDetailView(_BaseAIProviderView):
    """``PATCH /admin/api/ai-providers/{id}`` — partial update (DPA-validated)."""

    def patch(self, request: Request, provider_id: int) -> Response:
        provider = get_object_or_404(AIProvider, pk=provider_id)
        before = {
            "category": provider.category,
            "provider_key": provider.provider_key,
            "active": provider.active,
            "is_primary": provider.is_primary,
            "dpa_reference": provider.dpa_reference,
        }
        serializer = AIProviderAdminSerializer(
            provider, data=request.data, partial=True
        )
        serializer.is_valid(raise_exception=True)
        provider = serializer.save()
        admin_audit(
            admin_user=cast(AdminUser, request.admin_user),  # type: ignore[attr-defined]
            action="ai_provider.update",
            entity=provider,
            before=before,
            after={
                "category": provider.category,
                "provider_key": provider.provider_key,
                "active": provider.active,
                "is_primary": provider.is_primary,
                "dpa_reference": provider.dpa_reference,
            },
            ip=_client_ip(request),
        )
        return success(AIProviderAdminSerializer(provider).data)


class AIProviderTestConnectionView(_BaseAIProviderView):
    """``POST /admin/api/ai-providers/{id}/test-connection`` — verify creds."""

    def post(self, request: Request, provider_id: int) -> Response:
        provider = get_object_or_404(AIProvider, pk=provider_id)
        try:
            result = call_gateway(
                provider.category,
                {"action": "test_connection", "provider_id": provider.pk},
            )
        except AIGatewayError as exc:
            return success(
                {"ok": False, "detail": exc.message},
            )
        return success(
            {
                "ok": True,
                "provider_key": result.provider_key or provider.provider_key,
                "model_name": result.model_name or provider.model_name,
            }
        )


class AIUsageView(_BaseAIProviderView):
    """``GET /admin/api/ai-usage`` — usage aggregated by category."""

    def get(self, request: Request) -> Response:
        rows = (
            AIUsageLog.objects.values("category")
            .annotate(
                request_count=Sum("request_count"),
                tokens_used=Sum("tokens_used"),
                cost_usd=Sum("cost_usd"),
                call_count=Count("id"),
                success_count=Count("id", filter=Q(success=True)),
            )
            .order_by("category")
        )
        by_category = [
            {
                "category": row["category"],
                "request_count": int(row["request_count"] or 0),
                "tokens_used": int(row["tokens_used"] or 0),
                "cost_usd": str(row["cost_usd"] or Decimal("0.00")),
                "call_count": int(row["call_count"] or 0),
                "success_count": int(row["success_count"] or 0),
            }
            for row in rows
        ]
        totals = {
            "request_count": sum(r["request_count"] for r in by_category),
            "tokens_used": sum(r["tokens_used"] for r in by_category),
            "cost_usd": str(
                sum((Decimal(r["cost_usd"]) for r in by_category), Decimal("0.00"))
            ),
            "call_count": sum(r["call_count"] for r in by_category),
            "success_count": sum(r["success_count"] for r in by_category),
        }
        return success({"by_category": by_category, "totals": totals})
