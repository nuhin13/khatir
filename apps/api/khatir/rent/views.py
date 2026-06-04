"""Rent-requests API — create + queue under ``/api/v1/rent-requests`` (T-003 §3/§7).

A ``GenericViewSet`` whose queryset is **always** scoped through
``RentRequest.objects.for_user`` (``ForUserQuerySetMixin``) so a landlord/manager
never sees another user's requests — a missing scope is a P0 bug (§3). Reach the
endpoint only as a landlord or manager (``IsLandlordOrManager``); object-level
access is guarded by ``IsOwnerOfRentRequest``. Because list scoping already hides
other users' rows, an unknown/foreign id resolves to **404** (not 403).

Views stay thin: validate (serializer) → call a service → serialize. The landlord
is derived server-side from the lease in the service, never from the client.
"""

from __future__ import annotations

from typing import Any, cast

from django.db.models import QuerySet
from rest_framework import mixins, viewsets
from rest_framework.request import Request
from rest_framework.response import Response

from khatir.accounts.models import User
from khatir.core.permissions import ForUserQuerySetMixin, IsLandlordOrManager
from khatir.core.responses import created, success

from .models import RentRequest
from .permissions import IsOwnerOfRentRequest
from .serializers import RentRequestCreateSerializer, RentRequestSerializer
from .services import create_rent_request


class RentRequestViewSet(
    ForUserQuerySetMixin,
    mixins.ListModelMixin,
    mixins.RetrieveModelMixin,
    viewsets.GenericViewSet[RentRequest],
):
    """Create + list/detail the landlord's rent-request queue, scoped to the user."""

    queryset = RentRequest.objects.all()
    serializer_class = RentRequestSerializer
    permission_classes = [IsLandlordOrManager & IsOwnerOfRentRequest]

    def get_queryset(self) -> QuerySet[RentRequest]:
        qs = cast("QuerySet[RentRequest]", super().get_queryset())
        status_param = self.request.query_params.get("status")
        if status_param:
            qs = qs.filter(status=status_param)
        return qs

    def list(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        page = self.paginate_queryset(self.get_queryset())
        serializer = self.get_serializer(page, many=True)
        return self.get_paginated_response(serializer.data)

    def retrieve(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        rent_request = self.get_object()
        return success(RentRequestSerializer(rent_request).data)

    def create(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        serializer = RentRequestCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        rent_request = create_rent_request(
            actor=cast(User, request.user), **serializer.validated_data
        )
        return created(RentRequestSerializer(rent_request).data)
