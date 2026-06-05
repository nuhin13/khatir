"""Admin compliance endpoints — EPIC-16.T-003.

Mounted at ``/admin/api/`` (see :mod:`khatir.compliance.urls`, included from
``config/urls.py``). All routes require a valid admin Bearer token and the
``audit`` section role (``super`` / ``compliance`` — task §2).

* ``GET /admin/api/consent-records`` — paginated, filterable consent log.
* ``GET /admin/api/audit-log``       — paginated, filterable admin audit log,
  with a ``?format=csv`` streaming export (EPIC-16.T-002).

These logs are **read-only**: ``ConsentRecord`` (PDPA) and ``AdminAuditEntry``
are both append-only, so no create/update/delete endpoints exist. Supported
consent-record query filters:

* ``user``         — only records for this customer user id.
* ``consent_type`` — exact match on :class:`~khatir.compliance.enums.ConsentType`.
* ``granted_from`` — records granted on/after this ISO date/datetime.
* ``granted_to``   — records granted on/before this ISO date/datetime.

Supported audit-log query filters:

* ``admin_user``  — only entries performed by this admin user id.
* ``action``      — exact match on the ``domain.verb`` action string.
* ``entity_type`` — exact match on the affected ``app_label.model`` string.
* ``entity_id``   — exact match on the affected entity primary key.
* ``date_from``   — entries created on/after this ISO date/datetime.
* ``date_to``     — entries created on/before this ISO date/datetime.
* ``format=csv``  — stream the filtered set as a CSV download.
"""

from __future__ import annotations

import csv
from collections.abc import Iterator

from django.db.models import QuerySet
from django.http import StreamingHttpResponse
from rest_framework.permissions import BasePermission
from rest_framework.renderers import BaseRenderer, JSONRenderer
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from khatir.admin_portal.authentication import (
    AdminJWTAuthentication,
    IsAdminAuthenticated,
)
from khatir.admin_portal.models import AdminAuditEntry, AdminUser
from khatir.admin_portal.permissions import SECTION_ROLES, AdminSection
from khatir.core.pagination import StandardPageNumberPagination
from khatir.verification.models import VerificationLog

from .models import ConsentRecord
from .serializers import (
    AdminAuditEntrySerializer,
    ConsentRecordSerializer,
    VerificationLogSerializer,
)


class IsComplianceAdmin(BasePermission):
    """Gate compliance endpoints on the ``audit`` section roles (super / compliance).

    Reads the role off the ``AdminUser`` loaded by ``AdminJWTAuthentication``,
    mirroring the rest of the admin portal so authz stays consistent. ``super``
    is always inside the audit section set.
    """

    def has_permission(self, request: Request, view: object) -> bool:
        admin_user = getattr(request, "admin_user", None)
        if not isinstance(admin_user, AdminUser) or admin_user.disabled:
            return False
        return admin_user.role in SECTION_ROLES[AdminSection.AUDIT]


class ConsentRecordListView(APIView):
    """``GET /admin/api/consent-records`` — paginated, filterable consent log."""

    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsAdminAuthenticated, IsComplianceAdmin]

    def get(self, request: Request) -> Response:
        queryset = self._filtered_queryset(request)
        paginator = StandardPageNumberPagination()
        page = paginator.paginate_queryset(queryset, request, view=self)
        data = ConsentRecordSerializer(page, many=True).data
        return paginator.get_paginated_response(data)

    def _filtered_queryset(self, request: Request) -> QuerySet[ConsentRecord]:
        queryset = ConsentRecord.objects.all()
        params = request.query_params

        user = params.get("user")
        if user:
            queryset = queryset.filter(user_id=user)

        consent_type = params.get("consent_type")
        if consent_type:
            queryset = queryset.filter(consent_type=consent_type)

        granted_from = params.get("granted_from")
        if granted_from:
            queryset = queryset.filter(granted_at__gte=granted_from)

        granted_to = params.get("granted_to")
        if granted_to:
            queryset = queryset.filter(granted_at__lte=granted_to)

        return queryset


class _CsvEcho:
    """A write-only file-like object that returns each written row.

    Used with :class:`csv.writer` so rows can be yielded straight into a
    :class:`~django.http.StreamingHttpResponse` without buffering the whole
    export in memory.
    """

    def write(self, value: str) -> str:
        return value


class _CsvRenderer(BaseRenderer):
    """Passthrough renderer so DRF content negotiation accepts ``?format=csv``.

    The audit-log view streams its own :class:`StreamingHttpResponse`, so this
    renderer is never asked to serialise a body; it exists only to register the
    ``csv`` format with DRF's negotiation layer (which otherwise 404s on an
    unknown ``format`` query value).
    """

    media_type = "text/csv"
    format = "csv"

    def render(self, data: object, *args: object, **kwargs: object) -> bytes:
        return b""


AUDIT_CSV_COLUMNS = (
    "id",
    "admin_user",
    "action",
    "entity_type",
    "entity_id",
    "before_json",
    "after_json",
    "ip",
    "reason",
    "created_at",
)


class AdminAuditEntryListView(APIView):
    """``GET /admin/api/audit-log`` — paginated, filterable admin audit log.

    Returns the standard paginated JSON envelope by default. When called with
    ``?format=csv`` the full filtered set is streamed as a CSV download
    (EPIC-16.T-002). Read-only: ``AdminAuditEntry`` is append-only.
    """

    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsAdminAuthenticated, IsComplianceAdmin]
    renderer_classes = [JSONRenderer, _CsvRenderer]

    def get(self, request: Request) -> Response | StreamingHttpResponse:
        queryset = self._filtered_queryset(request)

        if request.accepted_renderer.format == "csv":
            return self._csv_response(queryset)

        paginator = StandardPageNumberPagination()
        page = paginator.paginate_queryset(queryset, request, view=self)
        data = AdminAuditEntrySerializer(page, many=True).data
        return paginator.get_paginated_response(data)

    def _filtered_queryset(self, request: Request) -> QuerySet[AdminAuditEntry]:
        queryset = AdminAuditEntry.objects.all().order_by("-created_at")
        params = request.query_params

        admin_user = params.get("admin_user")
        if admin_user:
            queryset = queryset.filter(admin_user_id=admin_user)

        action = params.get("action")
        if action:
            queryset = queryset.filter(action=action)

        entity_type = params.get("entity_type")
        if entity_type:
            queryset = queryset.filter(entity_type=entity_type)

        entity_id = params.get("entity_id")
        if entity_id:
            queryset = queryset.filter(entity_id=entity_id)

        date_from = params.get("date_from")
        if date_from:
            queryset = queryset.filter(created_at__gte=date_from)

        date_to = params.get("date_to")
        if date_to:
            queryset = queryset.filter(created_at__lte=date_to)

        return queryset

    def _csv_response(
        self, queryset: QuerySet[AdminAuditEntry]
    ) -> StreamingHttpResponse:
        writer = csv.writer(_CsvEcho())

        def rows() -> Iterator[str]:
            yield writer.writerow(AUDIT_CSV_COLUMNS)
            for entry in queryset.iterator():
                data = AdminAuditEntrySerializer(entry).data
                yield writer.writerow(
                    [data[column] for column in AUDIT_CSV_COLUMNS]
                )

        response = StreamingHttpResponse(rows(), content_type="text/csv")
        response["Content-Disposition"] = (
            'attachment; filename="audit-log.csv"'
        )
        return response


class VerificationLogListView(APIView):
    """``GET /admin/api/verification-logs`` — paginated verification event log.

    Surfaces EPIC-17 :class:`~khatir.verification.models.VerificationLog`
    entries in the compliance console (T-009): **read-only**, exposing only the
    boolean ``result``, the date, and who requested it — never any raw Election
    Commission data. ``VerificationLog`` is append-only, so there are no
    create/update/delete endpoints. Supported query filters:

    * ``tenant``    — only entries for this tenant id.
    * ``requested_by`` — only entries initiated by this user id.
    * ``result``    — exact match on
      :class:`~khatir.verification.enums.VerificationResult`.
    * ``date_from`` — entries created on/after this ISO date/datetime.
    * ``date_to``   — entries created on/before this ISO date/datetime.
    """

    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsAdminAuthenticated, IsComplianceAdmin]

    def get(self, request: Request) -> Response:
        queryset = self._filtered_queryset(request)
        paginator = StandardPageNumberPagination()
        page = paginator.paginate_queryset(queryset, request, view=self)
        data = VerificationLogSerializer(page, many=True).data
        return paginator.get_paginated_response(data)

    def _filtered_queryset(self, request: Request) -> QuerySet[VerificationLog]:
        queryset = VerificationLog.objects.all()
        params = request.query_params

        tenant = params.get("tenant")
        if tenant:
            queryset = queryset.filter(tenant_id=tenant)

        requested_by = params.get("requested_by")
        if requested_by:
            queryset = queryset.filter(requested_by_id=requested_by)

        result = params.get("result")
        if result:
            queryset = queryset.filter(result=result)

        date_from = params.get("date_from")
        if date_from:
            queryset = queryset.filter(created_at__gte=date_from)

        date_to = params.get("date_to")
        if date_to:
            queryset = queryset.filter(created_at__lte=date_to)

        return queryset
