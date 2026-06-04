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
