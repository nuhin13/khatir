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
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from khatir.accounts.models import User
from khatir.core.exceptions import FeatureDisabledError
from khatir.core.permissions import ForUserQuerySetMixin, IsLandlordOrManager
from khatir.core.responses import created, success
from khatir.core.storage import store_encrypted
from khatir.properties.models import Unit

from .extraction import get_asr_provider, get_ocr_provider
from .flags import VOICE_TENANT_ENTRY, is_feature_enabled
from .models import Tenant
from .permissions import IsLeaseHolderForUser
from .serializers import (
    OcrRequestSerializer,
    OcrResponseSerializer,
    TenantCreateSerializer,
    TenantSerializer,
    TenantUpdateSerializer,
    VoiceRequestSerializer,
    VoiceResponseSerializer,
)
from .services import create_tenant, update_tenant
from .throttling import OcrUserThrottle, VoiceUserThrottle


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


class TenantOcrView(APIView):
    """``POST /api/v1/tenants/ocr`` — NID image → editable fields (T-005 §1).

    Accepts a multipart ``image``, stores it **encrypted** (T-003) under an
    opaque ``photo_ref``, runs OCR via the swappable extraction provider (T-004),
    and returns the normalized, editable :class:`ExtractedTenant` fields plus the
    ``photo_ref``. It does **not** create the tenant — that is T-007 (the review
    screen submits the edited fields). The raw provider payload and the image
    bytes never leave the server (privacy, self-review §14).

    Landlord/manager only; per-user rate-limited because each call hits a paid
    external OCR provider.
    """

    permission_classes = [IsLandlordOrManager]
    throttle_classes = [OcrUserThrottle]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        serializer = OcrRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        image = serializer.validated_data["image"]
        image_bytes = image.read()

        # Encrypt-at-rest first so the image is never held only in memory, then
        # extract; the opaque key is what the client carries forward.
        photo_ref = store_encrypted(image_bytes, kind="nid")
        extracted = get_ocr_provider().extract_from_image(image_bytes)

        payload = OcrResponseSerializer.from_extraction(extracted, photo_ref)
        return success(OcrResponseSerializer(payload).data)


class TenantVoiceView(APIView):
    """``POST /api/v1/tenants/voice`` — Bangla audio → editable fields (T-006 §1).

    Accepts a multipart ``audio`` clip of a landlord/tenant reading the NID
    details, transcribes + extracts fields via the swappable ASR extraction
    provider (T-004), and returns the normalized, editable
    :class:`ExtractedTenant` fields. It does **not** create the tenant (that is
    T-007/T-012, the voice-fill review screen) and does **not** retain the audio:
    the clip is read into memory, handed to the provider, then discarded —
    nothing is stored and the raw transcript never leaves the server (privacy,
    §2/§14).

    Gated by the ``voice_tenant_entry`` flag (§10, default on): when disabled the
    endpoint returns the standard ``feature_disabled`` 403 envelope before any
    provider call. Landlord/manager only; per-user rate-limited because each call
    hits a paid external ASR provider.
    """

    permission_classes = [IsLandlordOrManager]
    throttle_classes = [VoiceUserThrottle]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        if not is_feature_enabled(VOICE_TENANT_ENTRY, default=True):
            raise FeatureDisabledError("Voice tenant entry is disabled.")

        serializer = VoiceRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        audio = serializer.validated_data["audio"]
        audio_bytes = audio.read()

        # Extract, then let the bytes fall out of scope — the audio is never
        # persisted (privacy, §2). Only the normalized fields are returned.
        extracted = get_asr_provider().extract_from_audio(audio_bytes)

        payload = VoiceResponseSerializer.from_extraction(extracted)
        return success(VoiceResponseSerializer(payload).data)


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
