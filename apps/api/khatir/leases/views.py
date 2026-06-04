"""Leases API — CRUD + lifecycle under ``/api/v1/leases`` (T-003 §3/§7).

A ``GenericViewSet`` whose queryset is **always** scoped through
``Lease.objects.for_user`` (``ForUserQuerySetMixin``) so a user never sees
another user's leases — a missing scope is a P0 bug (§3). Reachable only as a
landlord or manager (``IsLandlordOrManager``); object access is guarded by
``IsOwnerOfLease``. Because list scoping already hides foreign rows, an
unknown/foreign id resolves to **404** (never 403, T-003 §15).

Views stay thin: validate (serializer) → call a service → serialize. The
landlord is derived server-side in the service, never from the client.
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

from .models import Lease
from .permissions import IsOwnerOfLease
from .serializers import (
    LeaseCreateSerializer,
    LeaseSerializer,
    LeaseTerminateSerializer,
    LeaseUpdateSerializer,
)
from .services import activate_lease, create_lease, terminate_lease, update_lease


class LeaseViewSet(
    ForUserQuerySetMixin,
    mixins.ListModelMixin,
    mixins.RetrieveModelMixin,
    viewsets.GenericViewSet[Lease],
):
    """CRUD + lifecycle for leases, scoped to the requesting user."""

    queryset = cast("QuerySet[Lease]", Lease.objects.all())
    serializer_class = LeaseSerializer
    permission_classes = [IsLandlordOrManager & IsOwnerOfLease]

    def list(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        page = self.paginate_queryset(self.get_queryset())
        serializer = self.get_serializer(page, many=True)
        return self.get_paginated_response(serializer.data)

    def retrieve(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        lease = self.get_object()
        return success(LeaseSerializer(lease).data)

    def create(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        serializer = LeaseCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        lease = create_lease(
            actor=cast(User, request.user), **serializer.validated_data
        )
        return created(LeaseSerializer(lease).data)

    def partial_update(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        lease = self.get_object()
        serializer = LeaseUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        lease = update_lease(
            actor=cast(User, request.user),
            lease=lease,
            **serializer.validated_data,
        )
        return success(LeaseSerializer(lease).data)

    @action(detail=True, methods=["post"], url_path="activate")
    def activate(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        """Activate a draft lease → generates its rent schedule (T-003 §7)."""
        lease = self.get_object()  # 404 if not visible to the user
        lease = activate_lease(actor=cast(User, request.user), lease=lease)
        return success(LeaseSerializer(lease).data)

    @action(detail=True, methods=["post"], url_path="terminate")
    def terminate(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        """End/terminate an active lease (T-003 §7)."""
        lease = self.get_object()  # 404 if not visible to the user
        serializer = LeaseTerminateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        lease = terminate_lease(
            actor=cast(User, request.user),
            lease=lease,
            **serializer.validated_data,
        )
        return success(LeaseSerializer(lease).data)
