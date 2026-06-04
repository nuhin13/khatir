"""Admin compliance endpoints — EPIC-16.T-003.

Mounted at ``/admin/api/`` (see :mod:`khatir.compliance.urls`, included from
``config/urls.py``). All routes require a valid admin Bearer token and the
``audit`` section role (``super`` / ``compliance`` — task §2).

* ``GET /admin/api/consent-records`` — paginated, filterable consent log.

The consent log is **read-only**: ``ConsentRecord`` is append-only (PDPA), so no
create/update/delete endpoints exist. Supported query filters:

* ``user``         — only records for this customer user id.
* ``consent_type`` — exact match on :class:`~khatir.compliance.enums.ConsentType`.
* ``granted_from`` — records granted on/after this ISO date/datetime.
* ``granted_to``   — records granted on/before this ISO date/datetime.
"""

from __future__ import annotations

from django.db.models import QuerySet
from rest_framework.permissions import BasePermission
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from khatir.admin_portal.authentication import (
    AdminJWTAuthentication,
    IsAdminAuthenticated,
)
from khatir.admin_portal.models import AdminUser
from khatir.admin_portal.permissions import SECTION_ROLES, AdminSection
from khatir.core.pagination import StandardPageNumberPagination

from .models import ConsentRecord
from .serializers import ConsentRecordSerializer


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
