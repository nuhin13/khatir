"""Tenant-initiated history-share API — ``POST /api/v1/me/history-shares``.

A TENANT (and only a tenant) creates a share to a specific landlord. There is
deliberately **no landlord-initiated** variant — a landlord can never originate
or pull a tenant's history. The endpoint is:

* **role-gated** to tenants (:class:`IsTenant`);
* **kill-switch gated** on ``history_flags_feature`` — checked here so a killed
  feature returns ``403 feature_disabled`` before any work, and re-checked inside
  the service as defence in depth;
* **consent-logged + factual-only + audited** — all handled by the service.

The view stays thin: validate (serializer) → delegate to the service → serialize.
The acting tenant comes from ``request.user`` in the service, never the body.
"""

from __future__ import annotations

from typing import Any

from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from khatir.core.exceptions import FeatureDisabledError
from khatir.core.permissions import IsTenant
from khatir.core.responses import created

from .flags import history_sharing_enabled
from .serializers import HistoryShareCreateSerializer, HistoryShareSerializer
from .services import create_history_share


class HistoryShareCreateView(APIView):
    """``POST /api/v1/me/history-shares`` — tenant creates a consent-gated share."""

    permission_classes = [IsTenant]

    def post(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        if not history_sharing_enabled():
            raise FeatureDisabledError(
                "Rental-history sharing is currently unavailable."
            )

        serializer = HistoryShareCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        share = create_history_share(
            acting_user=request.user,
            recipient_landlord=data["recipient_landlord"],
            scope=data.get("scope") or {},
            expires_at=data.get("expires_at"),
        )
        return created(HistoryShareSerializer(share).data)
