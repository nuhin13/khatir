"""DMP form API — generate PDF + retrieve a generated record (EPIC-05 T-005 §7).

``POST /api/v1/tenants/{id}/dmpform/pdf`` orchestrates the generation pipeline
(assemble → render → store → record → signed URL) for a tenant the requester
owns, and returns ``201`` with the record and a signed download URL.

``GET /api/v1/dmpforms/{id}`` returns a previously generated record, also owner
scoped. Both endpoints resolve a tenant the user cannot see to **404** (we never
reveal existence, ``04_coding_conventions.md`` §3). Free-tier is allowed — there
is no plan gate. Views stay thin: scope → call the service → serialize.
"""

from __future__ import annotations

from typing import Any, cast

from django.shortcuts import get_object_or_404
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from khatir.accounts.models import User
from khatir.core.permissions import IsLandlordOrManager
from khatir.core.responses import created, success
from khatir.tenants.models import Tenant

from .models import DMPFormRecord
from .serializers import DMPFormRecordSerializer
from .services import generate_dmp_pdf, signed_url_for_record


class DmpPdfGenerateView(APIView):
    """``POST /tenants/{id}/dmpform/pdf`` — generate a DMP PDF for a tenant."""

    permission_classes = [IsLandlordOrManager]

    def post(self, request: Request, tenant_id: int, *args: Any, **kwargs: Any) -> Response:
        tenant = get_object_or_404(
            Tenant.objects.for_user(request.user), pk=tenant_id
        )
        result = generate_dmp_pdf(tenant=tenant, actor=cast(User, request.user))
        return created(
            {
                "record": DMPFormRecordSerializer(result.record).data,
                "signed_url": result.signed_url,
            }
        )


class DmpFormRecordDetailView(APIView):
    """``GET /dmpforms/{id}`` — retrieve a generated record (owner scoped)."""

    permission_classes = [IsLandlordOrManager]

    def get(self, request: Request, record_id: int, *args: Any, **kwargs: Any) -> Response:
        visible_tenants = Tenant.objects.for_user(request.user)
        record = get_object_or_404(
            DMPFormRecord.objects.filter(tenant__in=visible_tenants),
            pk=record_id,
        )
        data = dict(DMPFormRecordSerializer(record).data)
        data["signed_url"] = signed_url_for_record(record)
        return success(data)
