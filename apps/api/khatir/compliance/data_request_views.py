"""PDPA data-request queue endpoints — EPIC-16.T-004.

Mounted at ``/admin/api/`` (see :mod:`khatir.compliance.urls`). Both routes
require a valid admin Bearer token and the ``audit`` section role
(``super`` / ``compliance`` — task §2). Lives in its own module (rather than
``compliance/views.py``) to keep the data-request queue self-contained.

* ``GET  /admin/api/data-requests`` — paginated, filterable queue of PDPA
  export / erasure requests. Query filters:

  * ``status`` — exact match on :class:`~khatir.compliance.enums.DataRequestStatus`.
  * ``type``   — exact match on :class:`~khatir.compliance.enums.DataRequestType`.
  * ``sla``    — ``overdue`` / ``due_soon`` / ``on_track`` (derived from ``sla_due``).

* ``POST /admin/api/data-requests/{id}/process`` — resolve a *pending* request.
  Body ``{"action": "approve"|"reject", "reason": "..."}``:

  * **approve** an ``export`` request → generate an export package (stub marker
    recorded in the admin audit ``after`` payload) and mark the request
    ``completed``.
  * **approve** a ``delete`` request → queue the erasure (stub marker) and mark
    the request ``processing`` (the actual cascade runs out of band).
  * **reject** (either type) → mark the request ``rejected``; a ``reason`` is
    mandatory.

  Every action stamps ``handled_by`` / ``completed_at`` and writes an immutable
  :class:`~khatir.admin_portal.models.AdminAuditEntry` (the staff-action trail).
  A request that is not pending is a 409 conflict (idempotent / no double-process).
"""

from __future__ import annotations

import datetime as dt
from typing import Any, cast

from django.conf import settings
from django.db import transaction
from django.db.models import QuerySet
from django.utils import timezone
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
from khatir.admin_portal.permissions import SECTION_ROLES, AdminSection
from khatir.core.exceptions import ConflictError, NotFoundError
from khatir.core.pagination import StandardPageNumberPagination
from khatir.core.responses import success

from .enums import DataRequestStatus, DataRequestType
from .models import DataRequest
from .serializers import (
    DataRequestProcessSerializer,
    DataRequestSerializer,
)


def _client_ip(request: Request) -> str | None:
    return request.META.get("REMOTE_ADDR")


class IsComplianceAdmin(BasePermission):
    """Gate the data-request queue on the ``audit`` section roles (super / compliance).

    Reads the role off the ``AdminUser`` loaded by ``AdminJWTAuthentication``,
    mirroring the rest of the admin portal so authz stays consistent. ``super``
    is always inside the audit section set.
    """

    def has_permission(self, request: Request, view: object) -> bool:
        admin_user = getattr(request, "admin_user", None)
        if not isinstance(admin_user, AdminUser) or admin_user.disabled:
            return False
        return admin_user.role in SECTION_ROLES[AdminSection.AUDIT]


@transaction.atomic
def process_data_request(
    *,
    data_request: DataRequest,
    admin_user: AdminUser,
    approve: bool,
    reason: str,
    ip: str | None = None,
) -> DataRequest:
    """Approve or reject a *pending* ``data_request``; record + audit the decision.

    Approving an export generates an export package and completes the request;
    approving a delete queues the erasure and moves it to ``processing``;
    rejecting marks it ``rejected`` (``reason`` mandatory). Both paths stamp
    ``handled_by`` / ``completed_at`` and write an immutable
    :class:`~khatir.admin_portal.models.AdminAuditEntry`.
    """
    before = {"status": data_request.status}
    now = timezone.now()
    action_after: dict[str, Any]

    if approve:
        if data_request.request_type == DataRequestType.EXPORT:
            new_status = DataRequestStatus.COMPLETED
            data_request.completed_at = now
            # STUB: real export-package generation (zip of the subject's data)
            # is a later task; record the decision marker for now.
            action_after = {
                "status": new_status,
                "decision": "approved",
                "export_package": "queued",
            }
            audit_action = "data_request.approve_export"
        else:  # DELETE
            new_status = DataRequestStatus.PROCESSING
            # STUB: the actual erasure cascade runs out of band; here we only
            # queue it and move the request into processing.
            action_after = {
                "status": new_status,
                "decision": "approved",
                "erasure": "queued",
            }
            audit_action = "data_request.approve_delete"
    else:
        new_status = DataRequestStatus.REJECTED
        data_request.completed_at = now
        action_after = {"status": new_status, "decision": "rejected"}
        audit_action = "data_request.reject"

    data_request.status = new_status
    data_request.handled_by = admin_user
    data_request.save(
        update_fields=["status", "handled_by", "completed_at", "updated_at"]
    )

    admin_audit(
        admin_user=admin_user,
        action=audit_action,
        entity=data_request,
        before=before,
        after=action_after,
        ip=ip,
        reason=reason,
    )
    return data_request


class DataRequestListView(APIView):
    """``GET /admin/api/data-requests`` — paginated, filterable request queue."""

    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsAdminAuthenticated, IsComplianceAdmin]

    def get(self, request: Request) -> Response:
        queryset = self._filtered_queryset(request)
        paginator = StandardPageNumberPagination()
        page = paginator.paginate_queryset(queryset, request, view=self)
        data = DataRequestSerializer(page, many=True).data
        return paginator.get_paginated_response(data)

    def _filtered_queryset(self, request: Request) -> QuerySet[DataRequest]:
        queryset = DataRequest.objects.all()
        params = request.query_params

        status = params.get("status")
        if status:
            queryset = queryset.filter(status=status)

        request_type = params.get("type")
        if request_type:
            queryset = queryset.filter(request_type=request_type)

        sla = params.get("sla")
        if sla:
            today = timezone.now().date()
            soon = today + dt.timedelta(days=settings.DATA_REQUEST_SLA_DUE_SOON_DAYS)
            if sla == "overdue":
                queryset = queryset.filter(sla_due__lt=today)
            elif sla == "due_soon":
                queryset = queryset.filter(sla_due__gte=today, sla_due__lte=soon)
            elif sla == "on_track":
                queryset = queryset.filter(sla_due__gt=soon)

        return queryset


class DataRequestProcessView(APIView):
    """``POST /admin/api/data-requests/{id}/process`` — approve or reject."""

    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsAdminAuthenticated, IsComplianceAdmin]

    def post(self, request: Request, request_id: int) -> Response:
        serializer = DataRequestProcessSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        data_request = self._get_pending(request_id)
        approve = serializer.validated_data["action"] == "approve"
        updated = process_data_request(
            data_request=data_request,
            admin_user=cast(AdminUser, request.admin_user),  # type: ignore[attr-defined]
            approve=approve,
            reason=serializer.validated_data.get("reason", ""),
            ip=_client_ip(request),
        )
        return success(DataRequestSerializer(updated).data)

    def _get_pending(self, request_id: int) -> DataRequest:
        try:
            data_request = DataRequest.objects.select_for_update().get(pk=request_id)
        except DataRequest.DoesNotExist as exc:
            raise NotFoundError("Data request not found.") from exc
        if data_request.status != DataRequestStatus.PENDING:
            raise ConflictError("This data request has already been processed.")
        return data_request


__all__ = [
    "DataRequestListView",
    "DataRequestProcessView",
    "IsComplianceAdmin",
    "process_data_request",
]
