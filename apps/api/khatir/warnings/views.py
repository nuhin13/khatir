"""Warnings API — issue + list under ``/api/v1/leases/{id}/warnings`` (T-002 §3/§7).

The ``warnings_feature`` kill-switch is checked **first** on every request: when
it is off the endpoint returns the standard ``feature_disabled`` 403 envelope
before any data is read or written (task §15 — this feature ships OFF-able by
design). The target lease is always resolved through ``Lease.objects.for_user``,
so a foreign/unknown lease is invisible and yields **404** (never a 403, never a
cross-landlord read). Reads then list only the requesting landlord's own
warnings on that lease via ``Warning.objects.for_user`` — there is no path that
returns another landlord's warning. The issuing ``landlord`` is taken from
``request.user`` in the service, never the client.
"""

from __future__ import annotations

from typing import Any, cast

from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from khatir.accounts.models import User
from khatir.core.exceptions import FeatureDisabledError, NotFoundError
from khatir.core.permissions import IsLandlordOrManager
from khatir.core.responses import created, success
from khatir.leases.models import Lease

from .flags import is_warnings_feature_enabled
from .models import Warning
from .serializers import WarningCreateSerializer, WarningSerializer
from .services import issue_warning


class LeaseWarningsView(APIView):
    """List + issue the warnings on one of the caller's own leases.

    ``GET`` returns the caller's own warnings on the lease; ``POST`` issues a new
    one. Both require landlord/manager role, gate on the ``warnings_feature``
    kill-switch first, and resolve the lease through the caller's ``for_user``
    scope (foreign lease → 404).
    """

    permission_classes = [IsLandlordOrManager]

    def _get_lease(self, request: Request, lease_pk: Any) -> Lease:
        """Resolve the URL lease within the caller's scope, or 404.

        Using ``Lease.objects.for_user`` means a foreign/unknown lease is simply
        invisible — we never reveal it exists (no cross-landlord leak).
        """
        lease = Lease.objects.for_user(request.user).filter(pk=lease_pk).first()
        if lease is None:
            raise NotFoundError("Lease not found.")
        return lease

    def get(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        # Kill-switch first — feature ships OFF-able by design (§15).
        if not is_warnings_feature_enabled():
            raise FeatureDisabledError("The warnings feature is disabled.")

        lease = self._get_lease(request, kwargs["lease_pk"])
        # Own warnings only — scoped by issuing landlord, then by this lease.
        warnings = Warning.objects.for_user(request.user).filter(lease=lease)
        return success(WarningSerializer(warnings, many=True).data)

    def post(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        # Kill-switch first — feature ships OFF-able by design (§15).
        if not is_warnings_feature_enabled():
            raise FeatureDisabledError("The warnings feature is disabled.")

        lease = self._get_lease(request, kwargs["lease_pk"])
        serializer = WarningCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        warning = issue_warning(
            actor=cast(User, request.user),
            lease=lease,
            **serializer.validated_data,
        )
        return created(WarningSerializer(warning).data)
