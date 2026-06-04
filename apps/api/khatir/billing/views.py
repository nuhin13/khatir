"""Billing API — subscription create/upgrade + current plan (T-004 §3/§7).

Two landlord/manager endpoints under ``/api/v1/billing``:

* ``GET  /billing/subscription`` — the caller's current plan plus tenant usage
  (``tenants_used`` / ``tenants_limit``; ``None`` limit = unlimited / free tier
  uses the configured free limit). Returns ``204`` when the caller has no
  subscription yet (they are on the implicit free tier).
* ``POST /billing/subscribe`` — subscribe or upgrade to a tier by key. Payment
  is **stubbed** (the service records a pending intent for paid tiers; §15).

Views stay thin: validate (serializer) → call a service → serialize. The acting
user is taken from ``request.user`` in the service for audit, never the client.
"""

from __future__ import annotations

from typing import Any, cast

from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from khatir.accounts.models import User
from khatir.core.permissions import IsLandlordOrManager
from khatir.core.responses import created, no_content, success
from khatir.tenants.usage import tenant_usage

from .serializers import SubscribeSerializer, SubscriptionSerializer
from .services import current_subscription, subscribe, tenant_limit_for


def _usage_context(user: User, limit: int | None) -> dict[str, Any]:
    """Build the ``{tenants_used, tenants_limit}`` serializer context.

    ``tenants_used`` reuses the tenants-domain usage selector (the single source
    of count truth). When the subscription tier has no cap (``limit is None``)
    the response reports ``tenants_limit = None`` (unlimited).
    """
    used = tenant_usage(user).tenants_used
    return {"tenants_used": used, "tenants_limit": limit}


class SubscriptionView(APIView):
    """``GET /api/v1/billing/subscription`` — current plan + usage (T-004 §7)."""

    permission_classes = [IsLandlordOrManager]

    def get(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        user = cast(User, request.user)
        subscription = current_subscription(user)
        if subscription is None:
            # No subscription row yet — the caller is on the implicit free tier.
            return no_content()
        context = _usage_context(user, tenant_limit_for(subscription))
        return success(SubscriptionSerializer(subscription, context=context).data)


class SubscribeView(APIView):
    """``POST /api/v1/billing/subscribe`` — subscribe / upgrade (T-004 §7).

    Payment is stubbed in the service for paid tiers (a pending intent is
    recorded; an admin confirms manually). Returns the resulting subscription.
    """

    permission_classes = [IsLandlordOrManager]

    def post(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        serializer = SubscribeSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = cast(User, request.user)
        subscription = subscribe(actor=user, **serializer.validated_data)
        context = _usage_context(user, tenant_limit_for(subscription))
        return created(SubscriptionSerializer(subscription, context=context).data)
