"""Buildings API — CRUD under ``/api/v1/buildings`` (T-003 §3/§7).

A ``ModelViewSet`` whose queryset is **always** scoped through
``Building.objects.for_user`` (``ForUserQuerySetMixin``) so a user never sees
another user's buildings — a missing scope is a P0 bug (§3). Reach the endpoint
only as a landlord or manager (``IsLandlordOrManager``); object-level access is
guarded by ``IsOwnerOfBuilding``. Because list scoping already hides other users'
rows, an unknown/foreign id resolves to **404** (not 403) — we never reveal that
the building exists (T-003 §15).

Views stay thin: validate (serializer) → call a service → serialize. Owner is set
server-side in the service, never from the client.
"""

from __future__ import annotations

from typing import Any, cast

from django.db.models import QuerySet
from rest_framework import mixins, viewsets
from rest_framework.decorators import action
from rest_framework.request import Request
from rest_framework.response import Response

from khatir.accounts.models import User
from khatir.core.permissions import ForUserQuerySetMixin, IsLandlordOrManager
from khatir.core.responses import created, no_content, success

from .models import Building, Unit
from .permissions import IsOwnerOfBuilding, IsOwnerOfUnit
from .serializers import (
    BuildingCreateSerializer,
    BuildingSerializer,
    BuildingUpdateSerializer,
    UnitCreateSerializer,
    UnitGenerateSerializer,
    UnitSerializer,
    UnitUpdateSerializer,
)
from .services import (
    create_building,
    create_unit,
    delete_building,
    delete_unit,
    generate_units,
    update_building,
    update_unit,
)


class BuildingViewSet(
    ForUserQuerySetMixin,
    mixins.ListModelMixin,
    mixins.RetrieveModelMixin,
    viewsets.GenericViewSet[Building],
):
    """CRUD for buildings, scoped to the requesting user."""

    queryset = cast("QuerySet[Building]", Building.objects.all())
    serializer_class = BuildingSerializer
    permission_classes = [IsLandlordOrManager & IsOwnerOfBuilding]

    def list(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        page = self.paginate_queryset(self.get_queryset())
        serializer = self.get_serializer(page, many=True)
        return self.get_paginated_response(serializer.data)

    def retrieve(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        building = self.get_object()
        return success(BuildingSerializer(building).data)

    def create(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        serializer = BuildingCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        building = create_building(
            owner=cast(User, request.user), **serializer.validated_data
        )
        return created(BuildingSerializer(building).data)

    def partial_update(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        building = self.get_object()
        serializer = BuildingUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        building = update_building(
            actor=cast(User, request.user),
            building=building,
            **serializer.validated_data,
        )
        return success(BuildingSerializer(building).data)

    def destroy(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        building = self.get_object()
        delete_building(actor=cast(User, request.user), building=building)
        return no_content()

    # ── nested units: /buildings/{id}/units[/generate] ───────────────────────

    @action(detail=True, methods=["get", "post"], url_path="units")
    def units(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        """List or create units under a building the user may access.

        GET lists the building's units (scoped via the building, already
        guaranteed visible by ``get_object``). POST creates a single unit.
        """
        building = self.get_object()  # 404 if not visible to the user

        if request.method == "POST":
            create_serializer = UnitCreateSerializer(data=request.data)
            create_serializer.is_valid(raise_exception=True)
            unit = create_unit(
                actor=cast(User, request.user),
                building=building,
                **create_serializer.validated_data,
            )
            return created(UnitSerializer(unit).data)

        # This viewset is generic over Building, but the nested action paginates
        # the building's Units — the queryset element type is intentionally Unit.
        units = cast("QuerySet[Unit]", Unit.objects.filter(building=building))
        page = self.paginate_queryset(units)  # type: ignore[arg-type]
        return self.get_paginated_response(UnitSerializer(page, many=True).data)

    @action(detail=True, methods=["post"], url_path="units/generate")
    def generate(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        """Bulk-create units from floors × per_floor + scheme (T-004 §7)."""
        building = self.get_object()  # 404 if not visible to the user

        serializer = UnitGenerateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        units = generate_units(
            actor=cast(User, request.user),
            building=building,
            **serializer.validated_data,
        )
        return created(UnitSerializer(units, many=True).data)


class UnitViewSet(
    ForUserQuerySetMixin,
    mixins.RetrieveModelMixin,
    viewsets.GenericViewSet[Unit],
):
    """Single-unit detail/update/delete at ``/api/v1/units/{id}`` (T-004 §7).

    Scoped through ``Unit.objects.for_user`` so a foreign/unknown unit resolves
    to **404** (never 403 — we do not reveal that the unit exists). The
    object-level guard ``IsOwnerOfUnit`` is a second layer over the list scope.
    """

    queryset = cast("QuerySet[Unit]", Unit.objects.all())
    serializer_class = UnitSerializer
    permission_classes = [IsLandlordOrManager & IsOwnerOfUnit]

    def retrieve(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        unit = self.get_object()
        return success(UnitSerializer(unit).data)

    def partial_update(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        unit = self.get_object()
        serializer = UnitUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        unit = update_unit(
            actor=cast(User, request.user),
            unit=unit,
            **serializer.validated_data,
        )
        return success(UnitSerializer(unit).data)

    def destroy(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        unit = self.get_object()
        delete_unit(actor=cast(User, request.user), unit=unit)
        return no_content()
