"""Platform-dashboard view — EPIC-11.T-005.

Self-contained on the committed admin authz layer (T-004 ``permissions.py``):
``IsAdminUser`` validates the dedicated admin JWT and ``RequiresAdminSection``
gates on the ``platform`` section (super / ops). No dependency on the customer
JWT realm or on ``request.user``.
"""

from __future__ import annotations

from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from khatir.core.responses import success

from .dashboard import get_platform_dashboard
from .permissions import AdminSection, IsAdminUser, RequiresAdminSection


class PlatformDashboardView(APIView):
    """``GET /admin/api/dashboard`` — platform-wide KPIs for the admin home.

    Aggregates across every user (no ``for_user`` scoping); cached 5 min; only
    reachable by ``super`` / ``ops`` admins (the ``platform`` section).
    """

    authentication_classes: list[type] = []
    permission_classes = [
        IsAdminUser,
        RequiresAdminSection(AdminSection.PLATFORM),
    ]

    def get(self, request: Request) -> Response:
        return success(get_platform_dashboard())
