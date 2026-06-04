"""Tenants API — CRUD under ``/api/v1/tenants`` (T-007 §3/§7).

Reads are **always** scoped through ``Tenant.objects.for_user`` so a
landlord/manager only ever sees tenants who hold a lease on one of their units;
an unknown/foreign tenant resolves to **404**, never 403 (T-007 §14). Object
writes are additionally guarded by ``IsLeaseHolderForUser``. The full NID is
never serialized — responses carry only the masked form (T-002).

Views stay thin: validate (serializer) → call a service → serialize. The acting
user is taken from ``request.user`` in the service for audit, never the client.
"""

from __future__ import annotations

from typing import Any, cast

from django.db.models import QuerySet
from rest_framework import mixins, viewsets
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from khatir.accounts.models import User
from khatir.core.permissions import ForUserQuerySetMixin, IsLandlordOrManager
from khatir.core.responses import created, success
from khatir.properties.models import Unit

from .models import Tenant
from .permissions import IsLeaseHolderForUser
from .serializers import (
    TenantCreateSerializer,
    TenantSerializer,
    TenantUpdateSerializer,
)
from .services import create_tenant, update_tenant


class TenantViewSet(
    ForUserQuerySetMixin,
    mixins.RetrieveModelMixin,
    viewsets.GenericViewSet[Tenant],
):
    """Create / retrieve / update tenants, scoped to the requesting user.

    Create is role-gated only (a brand-new tenant has no lease yet, so it is not
    in any ``for_user`` scope); retrieve/update add the object-level
    ``IsLeaseHolderForUser`` guard over the list scope.
    """

    queryset = cast("QuerySet[Tenant]", Tenant.objects.all())
    serializer_class = TenantSerializer

    def get_permissions(self) -> list[Any]:
        if self.action == "create":
            return [IsLandlordOrManager()]
        return [(IsLandlordOrManager & IsLeaseHolderForUser)()]

    def retrieve(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        tenant = self.get_object()
        return success(TenantSerializer(tenant).data)

    def create(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        serializer = TenantCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        tenant = create_tenant(
            actor=cast(User, request.user), **serializer.validated_data
        )
        return created(TenantSerializer(tenant).data)

    def partial_update(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        tenant = self.get_object()
        serializer = TenantUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        tenant = update_tenant(
            actor=cast(User, request.user),
            tenant=tenant,
            **serializer.validated_data,
        )
        return success(TenantSerializer(tenant).data)


class UnitTenantsView(APIView):
    """List the tenants holding a lease on a unit (``/api/v1/units/{id}/tenants``).

    The unit must be visible to the caller via ``Unit.objects.for_user`` — a
    foreign/unknown unit yields an empty list (the unit is simply invisible),
    never a leak. Tenants are returned masked.
    """

    permission_classes = [IsLandlordOrManager]

    def get(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        unit_pk = kwargs["unit_pk"]
        visible_units = Unit.objects.for_user(request.user).filter(pk=unit_pk)
        all_tenants = cast("QuerySet[Tenant]", Tenant.objects.all())
        tenants = (
            all_tenants.filter(leases__unit__in=visible_units)
            .distinct()
            .prefetch_related("family_members")
        )
        return success(TenantSerializer(tenants, many=True).data)
