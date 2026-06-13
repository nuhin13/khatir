"""Admin audit-log viewer endpoint — EPIC-11.T-011.

``GET /admin/api/audit-log`` — a searchable, filterable, paginated read of the
immutable :class:`~khatir.admin_portal.models.AdminAuditEntry` ledger written by
the T-002 ``admin_audit`` writer. Compliance (and super) only — the ``audit``
section in the role matrix (T-004 ``permissions.py``).

The endpoint is **read-only**: there is no create/update/delete route, mirroring
the append-only model. Filters (all optional, AND-combined):

* ``admin_user`` — acting admin id (``system`` / empty matches system actions).
* ``action``     — exact ``domain.verb`` action string.
* ``entity_type``— ``app_label.model_name`` of the affected entity.
* ``from`` / ``to`` — ISO-8601 ``created_at`` lower/upper bounds (inclusive).

Results are cursor-paginated newest-first (append-only set, per
``core.pagination``); each row carries the before/after JSON for the UI diff
expander and a denormalized ``actor`` label.
"""

from __future__ import annotations

from django.db.models import QuerySet
from django.utils.dateparse import parse_datetime
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from khatir.core.pagination import StandardCursorPagination

from .audit_serializers import AuditLogEntrySerializer
from .authentication import AdminJWTAuthentication, IsAdminAuthenticated
from .models import AdminAuditEntry
from .permissions import SECTION_ROLES, AdminSection
from .user_views import _UsersSectionPermission

#: Roles allowed to read the audit log (compliance + super).
_AUDIT_READ_ROLES = SECTION_ROLES[AdminSection.AUDIT]


class IsAuditReadAdmin(_UsersSectionPermission):
    """Read access to the audit section (super / compliance)."""

    allowed_roles = _AUDIT_READ_ROLES


def _apply_filters(
    queryset: QuerySet[AdminAuditEntry], request: Request
) -> QuerySet[AdminAuditEntry]:
    """Narrow ``queryset`` by the optional query-param filters (AND-combined)."""
    params = request.query_params

    admin_user = params.get("admin_user", "").strip()
    if admin_user:
        if admin_user.lower() == "system":
            queryset = queryset.filter(admin_user__isnull=True)
        elif admin_user.isdigit():
            queryset = queryset.filter(admin_user_id=int(admin_user))

    action = params.get("action", "").strip()
    if action:
        queryset = queryset.filter(action=action)

    entity_type = params.get("entity_type", "").strip()
    if entity_type:
        queryset = queryset.filter(entity_type=entity_type)

    date_from = params.get("from", "").strip()
    if date_from:
        parsed = parse_datetime(date_from)
        if parsed is not None:
            queryset = queryset.filter(created_at__gte=parsed)

    date_to = params.get("to", "").strip()
    if date_to:
        parsed = parse_datetime(date_to)
        if parsed is not None:
            queryset = queryset.filter(created_at__lte=parsed)

    return queryset


class AuditLogView(APIView):
    """``GET /admin/api/audit-log`` — paginated, filterable audit-log read."""

    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsAdminAuthenticated, IsAuditReadAdmin]

    def get(self, request: Request) -> Response:
        queryset = AdminAuditEntry.objects.select_related("admin_user").all()
        queryset = _apply_filters(queryset, request)

        paginator = StandardCursorPagination()
        page = paginator.paginate_queryset(queryset, request, view=self)
        data = AuditLogEntrySerializer(page, many=True).data
        return paginator.get_paginated_response(data)


__all__ = ["AuditLogView", "IsAuditReadAdmin"]
