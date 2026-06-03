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
from rest_framework.request import Request
from rest_framework.response import Response

from khatir.accounts.models import User
from khatir.core.permissions import ForUserQuerySetMixin, IsLandlordOrManager
from khatir.core.responses import created, no_content, success

from .models import Building
from .permissions import IsOwnerOfBuilding
from .serializers import (
    BuildingCreateSerializer,
    BuildingSerializer,
    BuildingUpdateSerializer,
)
from .services import create_building, delete_building, update_building


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
