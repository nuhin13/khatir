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

from rest_framework.permissions import AllowAny
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from khatir.core.exceptions import FeatureDisabledError, NotFoundError
from khatir.core.permissions import IsTenant
from khatir.core.responses import created, success

from .flags import history_sharing_enabled
from .models import HistoryShare
from .serializers import (
    HistoryShareCreateSerializer,
    HistoryShareOwnerSerializer,
    HistoryShareRecipientSerializer,
    HistoryShareSerializer,
)
from .services import (
    create_history_share,
    list_history_shares,
    revoke_history_share,
)


class HistoryShareCreateView(APIView):
    """``GET|POST /api/v1/me/history-shares`` — tenant lists / creates shares.

    * ``GET`` — full tenant transparency: the owning tenant sees ALL their own
      shares (what / who / when / status), regardless of lifecycle state. Not
      kill-switch gated — a tenant can always inspect what they have shared.
    * ``POST`` — tenant creates a new consent-gated share (kill-switch gated).
    """

    permission_classes = [IsTenant]

    def get(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        shares = list_history_shares(acting_user=request.user)
        data = HistoryShareOwnerSerializer(shares, many=True).data
        return success(data)

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


class HistoryShareRevokeView(APIView):
    """``POST /api/v1/me/history-shares/{id}/revoke`` — tenant revokes instantly.

    Tenant control: only the owning tenant may revoke, and only their own share
    (another tenant's id is reported as ``404``, never ``403``, so its existence
    never leaks). Revoking kills the share immediately and withdraws the linked
    consent, closing the recipient read path at once. Idempotent (re-revoking is
    a no-op). NOT kill-switch gated — withdrawing consent must always be possible
    even when the feature is otherwise disabled.
    """

    permission_classes = [IsTenant]

    def post(
        self, request: Request, share_id: int, *args: Any, **kwargs: Any
    ) -> Response:
        share = revoke_history_share(
            acting_user=request.user, share_id=share_id
        )
        return success(HistoryShareOwnerSerializer(share).data)


class HistoryShareRecipientView(APIView):
    """``GET /api/v1/history-shares/{token}`` — recipient reads factual stats.

    The opaque ``token`` is the capability: whoever holds the tenant-issued link
    may read, so there is no role/owner check (and never a landlord-initiated
    *lookup* — a landlord cannot enumerate or pull a tenant's history; they can
    only follow a token the tenant gave them). The view is:

    * **kill-switch gated** on ``history_flags_feature`` — a killed feature
      returns ``403 feature_disabled`` before any lookup;
    * **active + consent gated** — a revoked, expired, or consent-withdrawn share
      is indistinguishable from a non-existent one (``404``), so lifecycle state
      never leaks via the read path;
    * **read-only + factual-only** — only GET is defined, and the serializer
      surfaces the frozen factual snapshot with no subjective field and no export.
    """

    permission_classes = [AllowAny]

    def get(self, request: Request, token: str, *args: Any, **kwargs: Any) -> Response:
        if not history_sharing_enabled():
            raise FeatureDisabledError(
                "Rental-history sharing is currently unavailable."
            )

        share = (
            HistoryShare.objects.select_related("consent_record")
            .filter(token=token)
            .first()
        )
        # A missing, revoked, expired, or consent-withdrawn share all look alike:
        # 404, so the read path never reveals that a share once existed.
        if share is None or not share.is_readable():
            raise NotFoundError("This shared rental history is not available.")

        return success(HistoryShareRecipientSerializer(share).data)
