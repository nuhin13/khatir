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

from typing import Any, cast

from django.db.models import QuerySet
from rest_framework.exceptions import NotFound
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from khatir.accounts.models import User
from khatir.core import storage
from khatir.core.responses import created, success
from khatir.leases.models import RentSchedule
from khatir.leases.serializers import LeaseSerializer, RentScheduleSerializer
from khatir.maintenance.serializers import MaintenanceRequestSerializer
from khatir.maintenance.services import create_maintenance_request
from khatir.rent.enums import PaymentProofType
from khatir.rent.models import Payment, RentRequest
from khatir.rent.serializers import RentRequestSerializer
from khatir.rent.services import submit_payment_proof

from .me_serializers import (
    InAppProofSerializer,
    MeMaintenanceCreateSerializer,
    ReceiptSerializer,
)
from .permissions import IsLinkedTenant
from .tenant_account import (
    active_lease_for_user,
    leases_for_tenant_user,
)

# Cap on an inline-uploaded proof screenshot (bytes); mirrors the web-link page
# (EPIC-07 T-006). Enforced again here as a hard stop on what we read into memory.
_MAX_SCREENSHOT_BYTES = 8 * 1024 * 1024  # 8 MiB


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


class MeRentPayView(APIView):
    """``POST /api/v1/me/rent/{id}/pay`` — submit payment proof in-app.

    The in-app counterpart of the public web-link proof form (EPIC-07 T-006):
    the logged-in tenant submits a bKash/Nagad transaction id, a note, or a
    screenshot for one of *their own* rent requests. It feeds the **same**
    :func:`~khatir.rent.services.submit_payment_proof` pipeline as the web link
    — no new proof or status logic lives here (task §3).

    Scope is the load-bearing guarantee: ``{id}`` is resolved only within the
    tenant's own leases (``tenant_account`` helpers), so another tenant's request
    id resolves to a 404 and is never reachable — a missing scope is a P0
    security bug (``04_coding_conventions.md`` §3).
    """

    permission_classes = [IsLinkedTenant]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def post(self, request: Request, *args: Any, pk: int, **kwargs: Any) -> Response:
        leases = leases_for_tenant_user(request.user)
        rent_request = RentRequest.objects.filter(lease__in=leases, pk=pk).first()
        if rent_request is None:
            # Never reveal that another tenant's request exists.
            raise NotFound("Rent request not found.")

        body = InAppProofSerializer(data=request.data)
        body.is_valid(raise_exception=True)
        proof_type, value, photo_ref = self._build_proof(body.validated_data)

        submit_payment_proof(
            rent_request=rent_request,
            proof_type=proof_type,
            value=value,
            photo_ref=photo_ref,
        )
        rent_request.refresh_from_db()
        return created(RentRequestSerializer(rent_request).data)

    @staticmethod
    def _build_proof(data: dict[str, Any]) -> tuple[str, str, str]:
        """Map validated input → ``(type, value, photo_ref)`` for the proof.

        Mirrors the web page's precedence (``rent/web_views.py``): a screenshot
        wins (stored encrypted, returns an opaque ``photo_ref``), then a txn id
        (``bkash_txn``), then a note. The serializer has already guaranteed at
        least one is present.
        """
        upload = data.get("screenshot")
        if upload is not None:
            raw = upload.read(_MAX_SCREENSHOT_BYTES + 1)
            photo_ref = storage.store_encrypted(raw[:_MAX_SCREENSHOT_BYTES], kind="proof")
            return PaymentProofType.SCREENSHOT, "", photo_ref

        txn_id = (data.get("txn_id") or "").strip()
        if txn_id:
            return PaymentProofType.BKASH_TXN, txn_id[:255], ""

        note = (data.get("note") or "").strip()
        return PaymentProofType.NOTE, note[:255], ""


class MeMaintenanceView(APIView):
    """``POST /api/v1/me/maintenance`` — report maintenance in-app (T-004).

    The in-app counterpart of the landlord create endpoint: the logged-in tenant
    reports a problem on *their own* unit. The unit and the active lease are
    resolved from the tenant's active lease (``tenant_account`` helper) and never
    trusted from the client, so a tenant can only ever raise a request against
    their own unit — a tenant with no active lease gets a 404 and never reaches a
    foreign unit (a missing scope is a P0 security bug,
    ``04_coding_conventions.md`` §3).

    It feeds the **same** :func:`~khatir.maintenance.services.create_maintenance_request`
    pipeline as the landlord surface (audit + ``open`` status) — no maintenance
    logic is duplicated here (task §3).
    """

    permission_classes = [IsLinkedTenant]

    def post(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        lease = active_lease_for_user(request.user)
        if lease is None:
            raise NotFound("No active lease.")

        body = MeMaintenanceCreateSerializer(data=request.data)
        body.is_valid(raise_exception=True)

        req = create_maintenance_request(
            actor=cast(User, request.user),
            unit=lease.unit,
            lease_id=lease.pk,
            **body.validated_data,
        )
        return created(MaintenanceRequestSerializer(req).data)
