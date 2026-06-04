"""Maintenance API — CRUD + resolve under ``/api/v1/maintenance`` (T-002 §3/§7).

Scoped through ``MaintenanceRequest.objects.for_user`` (``ForUserQuerySetMixin``)
so a user never sees another user's requests; reachable only as landlord/manager
and guarded by ``IsOwnerOfMaintenanceRequest`` (foreign id -> 404). Resolving a
request auto-creates exactly one ``Expense``.
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
from khatir.core.responses import created, success

from .models import MaintenanceRequest
from .permissions import IsOwnerOfMaintenanceRequest
from .serializers import (
    MaintenanceRequestCreateSerializer,
    MaintenanceRequestSerializer,
    MaintenanceRequestUpdateSerializer,
    MaintenanceResolveSerializer,
)
from .services import (
    create_maintenance_request,
    resolve_maintenance_request,
    update_maintenance_request,
)


class MaintenanceRequestViewSet(
    ForUserQuerySetMixin,
    mixins.ListModelMixin,
    mixins.RetrieveModelMixin,
    viewsets.GenericViewSet[MaintenanceRequest],
):
    """CRUD + resolve for maintenance requests, scoped to the requesting user."""

    queryset = cast("QuerySet[MaintenanceRequest]", MaintenanceRequest.objects.all())
    serializer_class = MaintenanceRequestSerializer
    permission_classes = [IsLandlordOrManager & IsOwnerOfMaintenanceRequest]

    def list(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        page = self.paginate_queryset(self.get_queryset())
        serializer = self.get_serializer(page, many=True)
        return self.get_paginated_response(serializer.data)

    def retrieve(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        req = self.get_object()
        return success(MaintenanceRequestSerializer(req).data)

    def create(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        serializer = MaintenanceRequestCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        req = create_maintenance_request(
            actor=cast(User, request.user), **serializer.validated_data
        )
        return created(MaintenanceRequestSerializer(req).data)

    def partial_update(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        req = self.get_object()
        serializer = MaintenanceRequestUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        req = update_maintenance_request(
            actor=cast(User, request.user),
            request=req,
            **serializer.validated_data,
        )
        return success(MaintenanceRequestSerializer(req).data)

    @action(detail=True, methods=["post"], url_path="resolve")
    def resolve(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        """Resolve a request -> record cost + auto-create one Expense (idempotent)."""
        req = self.get_object()  # 404 if not visible to the user
        serializer = MaintenanceResolveSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        req = resolve_maintenance_request(
            actor=cast(User, request.user),
            request=req,
            **serializer.validated_data,
        )
        return success(MaintenanceRequestSerializer(req).data)
