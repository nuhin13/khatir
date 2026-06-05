"""Tenant self-service API — ``/api/v1/me/*`` (EPIC-19 · T-002).

The read-only surface a logged-in **tenant** uses to see their own rental data:

``GET /api/v1/me/lease``
    The tenant's current (``active``) lease, or 404 when they hold none.

``GET /api/v1/me/rent``
    Their rent schedule (every period of the active lease) plus the rent
    requests sent to them, so the tenant can see what is due and what has been
    asked for.

``GET /api/v1/me/receipts``
    Their confirmed payments, each carrying the generated receipt pointer.

Every endpoint is gated by ``IsLinkedTenant`` and reads **only** through the
``tenant_account`` scoping helpers (T-001) — a tenant can never reach another
tenant's rows; a missing scope is a P0 security bug
(``04_coding_conventions.md`` §3). These views deliberately reuse the existing
domain pipelines (leases selectors, rent models) and the existing serializers
rather than duplicating any proof/maintenance logic (task §3).
"""

from __future__ import annotations

from typing import Any

from django.db.models import QuerySet
from rest_framework.exceptions import NotFound
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from khatir.core.responses import success
from khatir.leases.models import RentSchedule
from khatir.leases.serializers import LeaseSerializer, RentScheduleSerializer
from khatir.rent.models import Payment, RentRequest
from khatir.rent.serializers import RentRequestSerializer

from .me_serializers import ReceiptSerializer
from .permissions import IsLinkedTenant
from .tenant_account import (
    active_lease_for_user,
    leases_for_tenant_user,
)


class MeLeaseView(APIView):
    """``GET /api/v1/me/lease`` — the tenant's current active lease."""

    permission_classes = [IsLinkedTenant]

    def get(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        lease = active_lease_for_user(request.user)
        if lease is None:
            raise NotFound("No active lease.")
        return success(LeaseSerializer(lease).data)


class MeRentView(APIView):
    """``GET /api/v1/me/rent`` — the tenant's rent schedule + requests.

    Scoped to every lease the tenant holds (so history stays reachable), read
    straight off the child rows. Returns a two-key payload so the client gets
    both the planned schedule and the asks in a single call.
    """

    permission_classes = [IsLinkedTenant]

    def get(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        leases = leases_for_tenant_user(request.user)
        schedule: QuerySet[RentSchedule] = (
            RentSchedule.objects.filter(lease__in=leases).order_by("lease", "period")
        )
        requests: QuerySet[RentRequest] = (
            RentRequest.objects.filter(lease__in=leases).order_by("-created_at")
        )
        return success(
            {
                "schedule": RentScheduleSerializer(schedule, many=True).data,
                "requests": RentRequestSerializer(requests, many=True).data,
            }
        )


class MeReceiptsView(APIView):
    """``GET /api/v1/me/receipts`` — the tenant's confirmed payments/receipts."""

    permission_classes = [IsLinkedTenant]

    def get(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        leases = leases_for_tenant_user(request.user)
        receipts: QuerySet[Payment] = (
            Payment.objects.filter(rent_request__lease__in=leases)
            .select_related("rent_request")
            .order_by("-verified_at", "-created_at")
        )
        return success(ReceiptSerializer(receipts, many=True).data)
