"""Gov-export API — generate a submission package + download it (EPIC-26 T-004 §1).

``POST /api/v1/gov-export`` builds a government-submission package for the
authenticated landlord and a given ``period`` (delegating to the EPIC-26 T-002
builder, which respects per-tenant data-sharing consent and writes the
``govexport.generate`` audit), then returns ``201`` with the ledger row and a
signed download URL.

``GET /api/v1/gov-export/{id}`` returns a previously generated row plus a fresh
signed download URL and writes a ``govexport.download`` audit. Both endpoints are
owner-scoped — a landlord only ever sees their own exports, and a foreign/unknown
id resolves to **404** (we never reveal existence, ``04_coding_conventions.md``
§3). The whole feature is gated behind the ``gov_export_enabled`` flag
(default OFF); when the flag is off both endpoints raise ``feature_disabled``.

Views stay thin: flag-gate → scope → call the builder → audit → serialize.
"""

from __future__ import annotations

from typing import Any, cast

from django.shortcuts import get_object_or_404
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from khatir.accounts.models import User
from khatir.core.audit import audit
from khatir.core.exceptions import FeatureDisabledError
from khatir.core.permissions import IsLandlord
from khatir.core.responses import created, success

from . import builder
from .flags import gov_export_enabled
from .models import GovExport
from .serializers import GenerateExportRequestSerializer, GovExportSerializer


def _require_feature_enabled() -> None:
    """Raise ``feature_disabled`` (403) when the gov-export flag is off."""
    if not gov_export_enabled():
        raise FeatureDisabledError("Government export is disabled.")


class GovExportGenerateView(APIView):
    """``POST /gov-export`` — generate a submission package for a period."""

    permission_classes = [IsLandlord]

    def post(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        _require_feature_enabled()
        serializer = GenerateExportRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        period = serializer.validated_data["period"]

        actor = cast(User, request.user)
        result = builder.build_export_package(landlord=actor, period=period, actor=actor)
        return created(
            {
                "export": GovExportSerializer(result.export).data,
                "signed_url": result.signed_url,
            }
        )


class GovExportDetailView(APIView):
    """``GET /gov-export/{id}`` — fetch a row + a fresh signed URL (owner scoped)."""

    permission_classes = [IsLandlord]

    def get(self, request: Request, export_id: int, *args: Any, **kwargs: Any) -> Response:
        _require_feature_enabled()
        export = get_object_or_404(
            GovExport.objects.filter(landlord=request.user), pk=export_id
        )
        signed_url = builder.signed_url_for_export(export)
        audit(
            actor=cast(User, request.user),
            action="govexport.download",
            target=export,
            before=None,
            after={"file_ref": export.file_ref, "period": export.period},
        )
        data = dict(GovExportSerializer(export).data)
        data["signed_url"] = signed_url
        return success(data)
