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

from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from khatir.accounts.models import User
from khatir.core.exceptions import FeatureDisabledError, NotFoundError
from khatir.core.permissions import IsLandlord, IsManager
from khatir.core.responses import created, success

from .flags import is_b2b_manager_enabled
from .models import ManagerOwnerLink
from .serializers import (
    ManagerOwnerLinkSerializer,
    OwnerLinkConsentSerializer,
    OwnerLinkRequestSerializer,
)
from .services import request_owner_link, respond_to_link


def _require_flag() -> None:
    """Block the manager surface unless ``b2b_manager_enabled`` is on."""
    if not is_b2b_manager_enabled():
        raise FeatureDisabledError("The B2B manager feature is not enabled.")


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
