"""Lease-document API — generate, edit clauses, render PDF (EPIC-18 · T-004 §7).

Three owner-scoped, audited endpoints:

* ``POST /api/v1/leases/{id}/generate-document`` — AI-draft a lease document for
  a lease the requester owns. Gated by the ``ai_lease_enabled`` flag (default on)
  and the paid-tier feature gate (AI lease generation is a paid feature, like
  NID verification); free-tier callers get the ``feature_requires_upgrade`` 402
  envelope before any gateway call. Returns ``201`` with the draft document.
* ``PATCH /api/v1/lease-documents/{id}`` — edit a *draft* document's clauses.
  ``final`` documents are locked (``409``). The required-clause guarantee is
  re-asserted by the service so an edit can never blank a mandatory clause.
* ``POST /api/v1/lease-documents/{id}/pdf`` — render the document to a PDF via the
  shared encrypted storage (EPIC-05 approach) and return a signed download URL.

Every endpoint resolves a lease/document the caller cannot see to **404** — we
never reveal existence (``04_coding_conventions.md`` §3). Views stay thin:
scope → (gate) → call a service → serialize. The acting user is derived
server-side, never from the client body.
"""

from __future__ import annotations

from typing import Any, cast

from django.db.models import QuerySet
from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from khatir.accounts.models import User
from khatir.billing.services import check_can_verify
from khatir.core.enums import ErrorCode
from khatir.core.exceptions import AppError, FeatureDisabledError
from khatir.core.permissions import IsLandlordOrManager
from khatir.core.responses import created, success
from khatir.leases.models import Lease

from .enums import LeaseDocumentStatus
from .flags import AI_LEASE_ENABLED, is_feature_enabled
from .models import LeaseDocument
from .serializers import LeaseDocumentEditSerializer, LeaseDocumentSerializer
from .services import (
    edit_lease_document,
    generate_lease_document,
    render_lease_document_pdf,
)


class DocumentLockedError(AppError):
    """Raised when editing a non-draft (``final``) lease document."""

    error_code = ErrorCode.CONFLICT
    status_code = status.HTTP_409_CONFLICT
    default_detail = "This document is finalized and can no longer be edited."


def _visible_documents(user: Any) -> QuerySet[LeaseDocument]:
    """Lease documents whose lease is visible to ``user`` (owner scope).

    Scoping through ``Lease.objects.for_user`` means a foreign/unknown document
    id resolves to **404**, never 403 — the existence of another user's document
    is never revealed.
    """
    visible_leases = Lease.objects.for_user(user)
    return cast(
        "QuerySet[LeaseDocument]",
        LeaseDocument.objects.filter(lease__in=visible_leases),
    )


class GenerateLeaseDocumentView(APIView):
    """``POST /leases/{id}/generate-document`` — AI-draft a lease document."""

    permission_classes = [IsLandlordOrManager]

    def post(self, request: Request, lease_id: int, *args: Any, **kwargs: Any) -> Response:
        if not is_feature_enabled(AI_LEASE_ENABLED, default=True):
            raise FeatureDisabledError("AI lease generation is disabled.")

        # Tier gate: AI lease generation is a paid-tier feature. Free-tier users
        # get ``feature_requires_upgrade`` (402) before any paid gateway call.
        check_can_verify(request.user)

        lease = get_object_or_404(Lease.objects.for_user(request.user), pk=lease_id)
        document = generate_lease_document(
            lease, generated_by=cast(User, request.user)
        )
        return created(LeaseDocumentSerializer(document).data)


class LeaseDocumentEditView(APIView):
    """``PATCH /lease-documents/{id}`` — edit a draft document's clauses."""

    permission_classes = [IsLandlordOrManager]

    def patch(
        self, request: Request, document_id: int, *args: Any, **kwargs: Any
    ) -> Response:
        document = get_object_or_404(_visible_documents(request.user), pk=document_id)
        if document.status != LeaseDocumentStatus.DRAFT:
            raise DocumentLockedError()

        serializer = LeaseDocumentEditSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        document = edit_lease_document(
            document,
            clauses=serializer.validated_data["clauses"],
            actor=cast(User, request.user),
        )
        return success(LeaseDocumentSerializer(document).data)


class LeaseDocumentPdfView(APIView):
    """``POST /lease-documents/{id}/pdf`` — render PDF → signed URL."""

    permission_classes = [IsLandlordOrManager]

    def post(
        self, request: Request, document_id: int, *args: Any, **kwargs: Any
    ) -> Response:
        document = get_object_or_404(_visible_documents(request.user), pk=document_id)
        result = render_lease_document_pdf(document, actor=cast(User, request.user))
        return success(
            {
                "document": LeaseDocumentSerializer(result.document).data,
                "signed_url": result.signed_url,
            }
        )
