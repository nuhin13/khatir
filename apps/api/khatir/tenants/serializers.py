"""DRF serializers for the tenants endpoints (T-007 §3).

The full NID number is **never** a serializer field — reads only ever expose the
``nid_number_masked`` (``****7788``) form (T-002). Writes accept the raw NID
through a write-only ``nid_number`` field that the service encrypts; it is never
echoed back. Family members are written nested and read nested. ``id`` columns
are serialized as strings for stable client JSON.
"""

from __future__ import annotations

from rest_framework import serializers

from .enums import VerificationStatus
from .extraction import ExtractedTenant
from .models import Tenant, TenantFamilyMember


class FamilyMemberSerializer(serializers.ModelSerializer[TenantFamilyMember]):
    """Read/write a single household member (nested under a tenant)."""

    id = serializers.CharField(read_only=True)

    class Meta:
        model = TenantFamilyMember
        fields = ("id", "name", "relation")
        read_only_fields = ("id",)


class TenantSerializer(serializers.ModelSerializer[Tenant]):
    """Masked read serializer — the full NID is never exposed here.

    Only ``nid_number_masked`` is serialized; there is no field that returns the
    decrypted number (the DMP form uses ``Tenant.get_nid()`` explicitly).
    """

    id = serializers.CharField(read_only=True)
    family_members = FamilyMemberSerializer(many=True, read_only=True)

    class Meta:
        model = Tenant
        fields = (
            "id",
            "name",
            "nid_number_masked",
            "dob",
            "address",
            "photo_ref",
            "verification_status",
            "verified_at",
            "is_app_user",
            "family_members",
            "created_at",
            "updated_at",
        )
        read_only_fields = fields


class TenantCreateSerializer(serializers.Serializer[dict[str, object]]):
    """Validates a create body. ``nid_number`` is write-only (encrypted in the
    service); family members may be supplied nested."""

    name = serializers.CharField(max_length=120)
    nid_number = serializers.CharField(
        max_length=40, write_only=True, required=False, allow_blank=True
    )
    dob = serializers.DateField(required=False, allow_null=True)
    address = serializers.CharField(required=False, allow_blank=True)
    photo_ref = serializers.CharField(
        max_length=255, required=False, allow_blank=True
    )
    family_members = FamilyMemberSerializer(many=True, required=False)


class TenantUpdateSerializer(serializers.Serializer[dict[str, object]]):
    """Validates a partial update body (PATCH). All fields optional.

    Supplying ``family_members`` *replaces* the tenant's household set.
    """

    name = serializers.CharField(max_length=120, required=False)
    nid_number = serializers.CharField(
        max_length=40, write_only=True, required=False, allow_blank=True
    )
    dob = serializers.DateField(required=False, allow_null=True)
    address = serializers.CharField(required=False, allow_blank=True)
    photo_ref = serializers.CharField(
        max_length=255, required=False, allow_blank=True
    )
    verification_status = serializers.ChoiceField(
        choices=VerificationStatus.choices, required=False
    )
    family_members = FamilyMemberSerializer(many=True, required=False)

    def validate(self, attrs: dict[str, object]) -> dict[str, object]:
        if not attrs:
            raise serializers.ValidationError(
                "Provide at least one field to update."
            )
        return attrs


class OcrRequestSerializer(serializers.Serializer[dict[str, object]]):
    """Validates the multipart OCR body — a single NID ``image`` file (T-005 §1).

    The file is read in the view, stored encrypted, and handed to the extraction
    provider; it is never persisted to a model field here. A ``FileField`` (not
    ``ImageField``) keeps intake decoder-agnostic — the OCR provider, not the
    API, is responsible for interpreting the bytes — and avoids a heavy Pillow
    dependency just to gate uploads.
    """

    image = serializers.FileField(write_only=True)


class VoiceRequestSerializer(serializers.Serializer[dict[str, object]]):
    """Validates the multipart voice body — a single Bangla ``audio`` clip (T-006 §1).

    The clip is read in the view, handed to the ASR extraction provider, and
    **discarded** after extraction (privacy, §14) — it is never stored. A
    ``FileField`` keeps intake codec-agnostic; the ASR provider, not the API,
    interprets the audio bytes.
    """

    audio = serializers.FileField(write_only=True)


class _ExtractedFieldSerializer(serializers.Serializer[dict[str, object]]):
    """One extracted value + its optional 0–1 confidence (``ExtractedField``)."""

    value = serializers.JSONField(allow_null=True)
    confidence = serializers.FloatField(allow_null=True)


class OcrResponseSerializer(serializers.Serializer[dict[str, object]]):
    """Editable extraction result returned by ``POST /tenants/ocr`` (T-005 §1).

    Carries the normalized, per-field :class:`ExtractedTenant` (each field with
    an optional confidence so the review UI can flag low-confidence values) plus
    the opaque ``photo_ref`` for the encrypted NID image. The raw provider
    payload and the source image bytes are never part of this shape (privacy,
    self-review §14).
    """

    name = _ExtractedFieldSerializer()
    nid_number = _ExtractedFieldSerializer()
    dob = _ExtractedFieldSerializer()
    address = _ExtractedFieldSerializer()
    photo_ref = serializers.CharField()

    @staticmethod
    def from_extraction(extracted: ExtractedTenant, photo_ref: str) -> dict[str, object]:
        """Build the response payload from an ``ExtractedTenant`` + ``photo_ref``.

        ``dob`` is serialized as an ISO date string; all other values pass
        through as-is (already normalized text or ``None``).
        """

        payload = _extracted_fields(extracted)
        payload["photo_ref"] = photo_ref
        return payload


class VoiceResponseSerializer(serializers.Serializer[dict[str, object]]):
    """Editable extraction result returned by ``POST /tenants/voice`` (T-006 §1).

    Mirrors :class:`OcrResponseSerializer` minus ``photo_ref``: voice has no
    stored artefact — the audio clip is discarded after extraction (§14), so the
    response carries only the normalized, per-field :class:`ExtractedTenant`.
    The raw transcript/provider payload is never part of this shape (privacy).
    """

    name = _ExtractedFieldSerializer()
    nid_number = _ExtractedFieldSerializer()
    dob = _ExtractedFieldSerializer()
    address = _ExtractedFieldSerializer()

    @staticmethod
    def from_extraction(extracted: ExtractedTenant) -> dict[str, object]:
        """Build the response payload from an ``ExtractedTenant`` (no photo_ref)."""
        return _extracted_fields(extracted)


def _extracted_fields(extracted: ExtractedTenant) -> dict[str, object]:
    """Normalized ``{field: {value, confidence}}`` map shared by OCR/voice.

    ``dob`` is serialized as an ISO date string; all other values pass through
    as-is (already normalized text or ``None``).
    """

    def _field(name: str) -> dict[str, object | None]:
        ef = getattr(extracted, name)
        value = ef.value.isoformat() if hasattr(ef.value, "isoformat") else ef.value
        return {"value": value, "confidence": ef.confidence}

    return {
        "name": _field("name"),
        "nid_number": _field("nid_number"),
        "dob": _field("dob"),
        "address": _field("address"),
    }
