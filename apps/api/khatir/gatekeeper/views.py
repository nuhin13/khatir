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

from django.db.models import Count, Q
from django.utils import timezone
from rest_framework.permissions import BasePermission
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from khatir.accounts.models import User
from khatir.core.exceptions import FeatureDisabledError, NotFoundError
from khatir.core.permissions import IsLandlordOrManager
from khatir.core.responses import created, no_content, success
from khatir.properties.models import Building

from .enums import VisitorEntryStatus
from .flags import is_gatekeeper_enabled
from .models import CaretakerAssignment, VisitorEntry
from .permissions import IsBuildingOwnerOrManager, IsCaretaker
from .serializers import (
    CaretakerAssignmentCreateSerializer,
    CaretakerAssignmentSerializer,
    VisitorEntrySerializer,
    VisitorReviewSerializer,
)
from .services import assign_caretaker, review_visitor_entry, revoke_caretaker


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


class _CaretakerViewMixin:
    """Shared flag gate + caretaker-role reach for the caretaker-facing endpoints.

    Row visibility is always the job of ``VisitorEntry.objects.for_user`` (active
    assignments only); this mixin only enforces the flag (§10) and the caretaker
    reach role (§4). Non-caretakers never reach these endpoints.
    """

    permission_classes = cast("list[type[BasePermission]]", [IsCaretaker])

    request: Request

    def _require_flag(self) -> None:
        if not is_gatekeeper_enabled():
            raise FeatureDisabledError("The gatekeeper feature is disabled.")


class CaretakerHomeView(_CaretakerViewMixin, APIView):
    """``GET /api/v1/caretaker/home`` — today's activity for assigned buildings (T-003).

    Summarises the caretaker's day across the buildings they are *actively*
    assigned to: how many visitors were logged today and how they split across
    pending/approved/denied. Strictly scoped through ``for_user`` so a caretaker
    only ever sees their own assigned buildings' activity.
    """

    def get(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        self._require_flag()
        today = timezone.localdate()
        todays = VisitorEntry.objects.for_user(request.user).filter(
            created_at__date=today
        )
        counts = todays.aggregate(
            total=Count("id"),
            pending=Count("id", filter=Q(status=VisitorEntryStatus.PENDING)),
            approved=Count("id", filter=Q(status=VisitorEntryStatus.APPROVED)),
            denied=Count("id", filter=Q(status=VisitorEntryStatus.DENIED)),
        )
        recent = todays.order_by("-created_at")[:20]
        return success(
            {
                "date": today.isoformat(),
                "counts": {
                    "total": counts["total"],
                    "pending": counts["pending"],
                    "approved": counts["approved"],
                    "denied": counts["denied"],
                },
                "recent": VisitorEntrySerializer(recent, many=True).data,
            }
        )


class CaretakerVisitorQueueView(_CaretakerViewMixin, APIView):
    """``GET /api/v1/caretaker/visitors`` — the pending visitor queue (T-003).

    Lists the *pending* visitor entries across the caretaker's actively assigned
    buildings, oldest first (FIFO — the visitor who has waited longest is acted
    on next). Scoped through ``for_user``.
    """

    def get(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        self._require_flag()
        queue = (
            VisitorEntry.objects.for_user(request.user)
            .filter(status=VisitorEntryStatus.PENDING)
            .order_by("created_at")
        )
        return success(VisitorEntrySerializer(queue, many=True).data)


class CaretakerVisitorReviewView(_CaretakerViewMixin, APIView):
    """``POST /api/v1/caretaker/visitors/{id}/review`` — approve/deny (T-003).

    Resolves the entry through ``for_user`` so an entry at a building the
    caretaker is not actively assigned to is **404** (never reveal existence).
    The decision is validated, applied + audited (``visitor.review``) in the
    service, and the reviewing caretaker is recorded server-side as ``logged_by``.
    """

    def post(
        self, request: Request, entry_id: str, *args: Any, **kwargs: Any
    ) -> Response:
        self._require_flag()
        entry = (
            VisitorEntry.objects.for_user(request.user).filter(pk=entry_id).first()
        )
        if entry is None:
            raise NotFoundError("Visitor entry not found.")
        serializer = VisitorReviewSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        entry = review_visitor_entry(
            actor=cast(User, request.user),
            entry=entry,
            decision=serializer.validated_data["decision"],
        )
        return success(VisitorEntrySerializer(entry).data)
