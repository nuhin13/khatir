"""Caretaker-assignment API — nested under buildings (T-002 §3/§7).

``POST /api/v1/buildings/{id}/caretakers``  — owner/manager assigns a caretaker.
``GET  /api/v1/buildings/{id}/caretakers``  — list a building's assignments.
``DELETE /api/v1/buildings/{id}/caretakers/{assignment_id}`` — revoke one.

The building is **always** resolved through ``Building.objects.for_user`` so a
foreign/unknown building id is **404** (we never reveal it exists, §15), and the
object permission ``IsBuildingOwnerOrManager`` is the second isolation layer over
that scope. Reach is role-gated to landlord/manager (``IsLandlordOrManager``);
caretakers/tenants/anonymous never get here. The whole feature is behind the
``gatekeeper_enabled`` flag (§10, default on) — when off, requests get the
standard ``feature_disabled`` 403 envelope before any work.

Views stay thin: validate (serializer) → call a service → serialize. ``assigned_by``
is set server-side from ``request.user`` in the service, never from the client.
"""

from __future__ import annotations

from typing import Any, cast

from rest_framework.permissions import BasePermission
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from khatir.accounts.models import User
from khatir.core.exceptions import FeatureDisabledError, NotFoundError
from khatir.core.permissions import IsLandlordOrManager
from khatir.core.responses import created, no_content, success
from khatir.properties.models import Building

from .flags import is_gatekeeper_enabled
from .models import CaretakerAssignment
from .permissions import IsBuildingOwnerOrManager
from .serializers import (
    CaretakerAssignmentCreateSerializer,
    CaretakerAssignmentSerializer,
)
from .services import assign_caretaker, revoke_caretaker


class _GatekeeperViewMixin:
    """Shared building resolution + flag/permission gating for the endpoints."""

    permission_classes = cast(
        "list[type[BasePermission]]",
        [IsLandlordOrManager & IsBuildingOwnerOrManager],
    )

    request: Request

    def _require_flag(self) -> None:
        if not is_gatekeeper_enabled():
            raise FeatureDisabledError("The gatekeeper feature is disabled.")

    def _get_building(self, building_id: str) -> Building:
        """Resolve a building visible to the caller, or 404 (never reveal existence)."""
        building = Building.objects.for_user(self.request.user).filter(
            pk=building_id
        ).first()
        if building is None:
            raise NotFoundError("Building not found.")
        # Second isolation layer: object-level owner/manager check.
        self.check_object_permissions(self.request, building)  # type: ignore[attr-defined]
        return building


class BuildingCaretakersView(_GatekeeperViewMixin, APIView):
    """List / create caretaker assignments for one building (T-002 §7)."""

    def get(self, request: Request, building_id: str, *args: Any, **kwargs: Any) -> Response:
        self._require_flag()
        building = self._get_building(building_id)
        assignments = CaretakerAssignment.objects.for_user(request.user).filter(
            building=building
        )
        return success(CaretakerAssignmentSerializer(assignments, many=True).data)

    def post(self, request: Request, building_id: str, *args: Any, **kwargs: Any) -> Response:
        self._require_flag()
        building = self._get_building(building_id)
        serializer = CaretakerAssignmentCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        assignment = assign_caretaker(
            actor=cast(User, request.user),
            building=building,
            caretaker_id=serializer.validated_data["caretaker_id"],
        )
        return created(CaretakerAssignmentSerializer(assignment).data)


class BuildingCaretakerDetailView(_GatekeeperViewMixin, APIView):
    """Revoke a single caretaker assignment under a building (T-002 §7)."""

    def delete(
        self,
        request: Request,
        building_id: str,
        assignment_id: str,
        *args: Any,
        **kwargs: Any,
    ) -> Response:
        self._require_flag()
        building = self._get_building(building_id)
        assignment = CaretakerAssignment.objects.for_user(request.user).filter(
            pk=assignment_id, building=building
        ).first()
        if assignment is None:
            raise NotFoundError("Caretaker assignment not found.")
        revoke_caretaker(actor=cast(User, request.user), assignment=assignment)
        return no_content()
