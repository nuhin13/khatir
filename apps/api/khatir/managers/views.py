"""Manager owner-link API (EPIC-22 · T-003 §3/§7).

Three endpoints, all behind the ``b2b_manager_enabled`` feature flag:

- ``POST /api/v1/manager/owners`` — a **manager** requests a link to an owner.
  Creates a ``pending`` link and notifies the owner for consent (EPIC-15).
- ``GET  /api/v1/manager/owners`` — a **manager** lists the owners they may act
  for: **active links only** (the same scope EPIC-03's ``for_user`` uses).
- ``POST /api/v1/manager/owners/{link_id}/consent`` — the **owner** accepts or
  declines a pending request. Accepting writes a consent record and activates
  the link; declining revokes it.

All writes are audited in the service layer. Role gating is via the shared
permission classes; row-level isolation is enforced by scoping every lookup to
the requesting user (manager or owner), so a cross-user id yields **404**.
"""

from __future__ import annotations

from typing import Any, cast

from django.core.cache import cache
from django.http import HttpResponse
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from khatir.accounts.models import User
from khatir.core.audit import audit
from khatir.core.config import get_config
from khatir.core.exceptions import FeatureDisabledError, NotFoundError
from khatir.core.permissions import IsLandlord, IsManager
from khatir.core.responses import created, success

from .dashboard import get_manager_dashboard
from .flags import is_b2b_manager_enabled
from .models import ManagerOwnerLink
from .report import REPORT_VERSION, build_owner_report, render_owner_report_pdf
from .serializers import (
    ManagerDashboardSerializer,
    ManagerOwnerLinkSerializer,
    OwnerLinkConsentSerializer,
    OwnerLinkRequestSerializer,
)
from .services import request_owner_link, respond_to_link

#: Short cache TTL (seconds) for the consolidated dashboard — smooths the
#: open-screen burst while keeping numbers fresh (mirrors EPIC-09, ``§15``).
_DASH_CACHE_TTL = 60
_DASH_CACHE_PREFIX = "manager_dashboard:"
#: Fallback when the ``dashboard_months_default`` config row is absent.
_DEFAULT_MONTHS = 6
#: Clamp the param so a client can never request an unbounded series.
_MAX_MONTHS = 24


def _require_flag() -> None:
    """Block the manager surface unless ``b2b_manager_enabled`` is on."""
    if not is_b2b_manager_enabled():
        raise FeatureDisabledError("The B2B manager feature is not enabled.")


def _months_default() -> int:
    """The configured default month window (EPIC-09 T-003), with a fallback."""
    value = get_config("dashboard_months_default", default=_DEFAULT_MONTHS)
    try:
        return max(1, int(value))
    except (TypeError, ValueError):
        return _DEFAULT_MONTHS


def _parse_months(request: Request) -> int:
    """Resolve the ``months`` window: query param, else config default."""
    raw = request.query_params.get("months")
    if raw is None or raw == "":
        return _months_default()
    try:
        months = int(raw)
    except (TypeError, ValueError):
        return _months_default()
    return max(1, min(months, _MAX_MONTHS))


class ManagerOwnersView(APIView):
    """``/api/v1/manager/owners`` — list active owners; request a new link."""

    permission_classes = [IsManager]

    def get(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        _require_flag()
        manager = cast(User, request.user)
        # Active links only — the manager's true ``for_user`` scope (T-001).
        links = (
            ManagerOwnerLink.objects.for_manager(manager)
            .active()
            .select_related("owner")
        )
        return success(ManagerOwnerLinkSerializer(links, many=True).data)

    def post(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        _require_flag()
        manager = cast(User, request.user)
        serializer = OwnerLinkRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        owner = User.objects.filter(pk=data["owner_id"]).first()
        if owner is None:
            raise NotFoundError("Owner not found.")

        link = request_owner_link(
            manager=manager,
            owner=owner,
            permissions_scope=data["permissions_scope"],
        )
        return created(ManagerOwnerLinkSerializer(link).data)


class OwnerLinkConsentView(APIView):
    """``/api/v1/manager/owners/{link_id}/consent`` — owner accept/decline."""

    permission_classes = [IsLandlord]

    def post(
        self, request: Request, link_id: int, *args: Any, **kwargs: Any
    ) -> Response:
        _require_flag()
        owner = cast(User, request.user)
        # Scope the lookup to the requesting owner: a link the owner does not
        # own is indistinguishable from a missing one (404, never 403).
        link = ManagerOwnerLink.objects.filter(pk=link_id, owner=owner).first()
        if link is None:
            raise NotFoundError("Link request not found.")

        serializer = OwnerLinkConsentSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        link = respond_to_link(
            owner=owner,
            link=link,
            accept=serializer.validated_data["accept"],
        )
        return success(ManagerOwnerLinkSerializer(link).data)


class ManagerDashboardView(APIView):
    """``GET /api/v1/manager/dashboard`` — metrics across active-linked owners.

    Aggregates the EPIC-09 dashboard for every owner the manager is **actively**
    linked to (consent enforced), returning per-owner rows plus a summed total.
    Manager-scoped and gated by ``b2b_manager_enabled``; the payload is cached
    per manager for a short TTL (never a global key, ``§15``).
    """

    permission_classes = [IsManager]

    def get(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        _require_flag()
        manager = cast(User, request.user)
        months = _parse_months(request)

        ck = f"{_DASH_CACHE_PREFIX}{manager.pk}:{months}"
        payload = cache.get(ck)
        if payload is None:
            dashboard = get_manager_dashboard(manager, months=months)
            payload = ManagerDashboardSerializer(dashboard).data
            cache.set(ck, payload, _DASH_CACHE_TTL)
        return success(payload)


class ManagerOwnerReportView(APIView):
    """``GET /api/v1/manager/owners/{owner_id}/report`` — per-owner PDF report.

    Renders a one-page summary (collection, occupancy, expenses) for a single
    owner the manager is **actively** linked to, reusing the EPIC-09 selectors
    and the EPIC-05 PDF primitive (see :mod:`khatir.managers.report`).

    Scoped to active links only: an owner the manager has no *active* link to —
    pending, revoked, or another manager's — is indistinguishable from one that
    does not exist (**404**, never 403). A manager reading an owner's
    personal/financial data is an auditable access event, written here on the
    successful read (``04_coding_conventions.md`` §11).
    """

    permission_classes = [IsManager]

    def get(
        self, request: Request, owner_id: int, *args: Any, **kwargs: Any
    ) -> HttpResponse:
        _require_flag()
        manager = cast(User, request.user)
        months = _parse_months(request)

        # Resolve the owner only through this manager's *active* links — the
        # single source of truth for accessible owners (T-001). Any other id
        # (no link, pending, revoked, another manager's) yields 404.
        link = (
            ManagerOwnerLink.objects.for_manager(manager)
            .active()
            .select_related("owner")
            .filter(owner_id=owner_id)
            .first()
        )
        if link is None:
            raise NotFoundError("Owner not found.")
        owner = link.owner

        report = build_owner_report(owner, months=months)
        pdf = render_owner_report_pdf(report)

        # The access — a manager reading this owner's financials — is audited.
        audit(
            actor=manager,
            action="manager.owner_report.read",
            target=link,
            before=None,
            after={
                "owner_id": owner.pk,
                "months": months,
                "report_version": REPORT_VERSION,
            },
        )

        response = HttpResponse(pdf, content_type="application/pdf")
        response["Content-Disposition"] = (
            f'inline; filename="owner-{owner.pk}-report.pdf"'
        )
        return response
