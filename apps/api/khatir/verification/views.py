"""Verification API — ``/api/v1/tenants/{id}/verify`` + ``/verification`` (T-004 §7).

The verify endpoint orchestrates the full flow with **fail-fast gates** in the
order the task mandates (§15): tier → flag → (resolve tenant) → consent → check.

* **tier gate** (EPIC-10 T-009): NID verification is a paid-tier feature;
  free-tier callers get the ``feature_requires_upgrade`` (402) envelope before any
  tenant is resolved, consent recorded, NID decrypted, or vendor called.
* **flag gate** (``nid_verification_enabled``, default on): the feature kill-switch;
  off → standard ``feature_disabled`` (403) envelope.
* **owner scope**: the tenant is resolved through ``Tenant.objects.for_user`` and the
  object-level ``IsLeaseHolderForUser`` guard, so a foreign/unknown tenant is **404**
  (never revealing existence).

The service does the consent → decrypt → provider → log → status-transition work and
the auditing. The response is boolean-only — ``{result, date}`` — never any raw EC
field or the NID.
"""

from __future__ import annotations

from typing import Any, cast

from django.shortcuts import get_object_or_404
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from khatir.accounts.models import User
from khatir.billing.services import check_can_verify
from khatir.core.exceptions import FeatureDisabledError
from khatir.core.permissions import IsLandlordOrManager
from khatir.core.responses import success
from khatir.tenants.models import Tenant

from .flags import NID_VERIFICATION_ENABLED, is_feature_enabled
from .serializers import VerificationResultSerializer
from .services import latest_verification, verify_tenant


def _scoped_tenant(request: Request, tenant_pk: Any) -> Tenant:
    """Resolve a tenant visible to the caller, else 404 (never reveal existence).

    Resolution goes through ``Tenant.objects.for_user`` — the single source of
    tenant-visibility truth (a tenant holds a lease on a unit the caller owns or
    manages). A foreign/unknown tenant is indistinguishable from one that does not
    exist, so the caller gets **404**, never 403.
    """
    return get_object_or_404(Tenant.objects.for_user(request.user), pk=tenant_pk)


class VerifyView(APIView):
    """``POST /api/v1/tenants/{id}/verify`` — run EC verification (T-004 §2/§7).

    Owner-scoped, landlord/manager only, tier- and flag-gated. Returns the
    boolean-only ``{result, date}``; all raw EC data and the NID stay server-side.
    """

    permission_classes = [IsLandlordOrManager]

    def post(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        # 1. Tier gate (T-009): free / non-verification tiers → feature_requires_upgrade
        #    (402) before any tenant resolution or paid vendor call.
        check_can_verify(request.user)

        # 2. Flag gate: kill-switch off → feature_disabled (403).
        if not is_feature_enabled(NID_VERIFICATION_ENABLED, default=True):
            raise FeatureDisabledError("NID verification is disabled.")

        # 3. Resolve the tenant in the caller's scope (foreign/unknown → 404).
        tenant = _scoped_tenant(request, kwargs["tenant_pk"])

        # 4. Consent → decrypt → provider → log → status (+ audit) in the service.
        log = verify_tenant(actor=cast(User, request.user), tenant=tenant)

        return success(VerificationResultSerializer(log).data)


class VerificationView(APIView):
    """``GET /api/v1/tenants/{id}/verification`` — last verification result (T-004 §7).

    Owner-scoped, landlord/manager only. Returns the most recent boolean-only
    ``{result, date}`` for the tenant, or ``{result: null, date: null}`` if never
    verified (stable shape). Not gated by
    tier/flag — reading an existing result is always allowed (the flag only kills new
    verification runs).
    """

    permission_classes = [IsLandlordOrManager]

    def get(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        tenant = _scoped_tenant(request, kwargs["tenant_pk"])
        log = latest_verification(tenant)
        if log is None:
            # Stable shape even when never verified — both fields null.
            return success({"result": None, "date": None})
        return success(VerificationResultSerializer(log).data)
