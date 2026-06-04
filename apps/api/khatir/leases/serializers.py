"""DRF serializers for the leases endpoints (T-003 §3/§7).

Input validation only. ``landlord`` is **never** read from the client — it is
derived server-side from the unit's building owner (T-003 §2/§15). ``unit`` and
``tenant`` are supplied by id; the service resolves and scopes them. The read
serializer exposes the resolved ``landlord_id`` read-only so a client can never
set it.
"""

from __future__ import annotations

from rest_framework import serializers

from .enums import LeaseStatus
from .models import Lease


class LeaseSerializer(serializers.ModelSerializer[Lease]):
    """Read/serialize a lease for API responses.

    ``id`` and the FK ids are serialized as strings for stable client JSON and
    are read-only so a client can never re-parent the lease or reassign it.
    """

    id = serializers.CharField(read_only=True)
    unit_id = serializers.CharField(read_only=True)
    tenant_id = serializers.CharField(read_only=True)
    landlord_id = serializers.CharField(read_only=True)

    class Meta:
        model = Lease
        fields = (
            "id",
            "unit_id",
            "tenant_id",
            "landlord_id",
            "start_date",
            "end_date",
            "rent",
            "advance",
            "status",
            "signed_pdf_ref",
            "created_at",
            "updated_at",
        )
        read_only_fields = (
            "id",
            "unit_id",
            "tenant_id",
            "landlord_id",
            "status",
            "created_at",
            "updated_at",
        )


class LeaseCreateSerializer(serializers.Serializer[dict[str, object]]):
    """Validates a create body. Landlord is server-derived, never from the client.

    The lease is always created as a ``draft`` (status is not client-settable);
    activation is a separate lifecycle endpoint.
    """

    unit_id = serializers.CharField()
    tenant_id = serializers.CharField()
    start_date = serializers.DateField()
    end_date = serializers.DateField()
    rent = serializers.DecimalField(max_digits=12, decimal_places=2, min_value=0)
    advance = serializers.DecimalField(
        max_digits=12, decimal_places=2, min_value=0, required=False
    )

    def validate(self, attrs: dict[str, object]) -> dict[str, object]:
        if attrs["end_date"] < attrs["start_date"]:  # type: ignore[operator]
            raise serializers.ValidationError(
                {"end_date": "end_date must be on or after start_date."}
            )
        return attrs


class LeaseUpdateSerializer(serializers.Serializer[dict[str, object]]):
    """Validates a partial update body (PATCH). All fields optional.

    Only the financial terms and dates are editable, and only while the lease is
    a draft (enforced in the service). FKs and status are immutable here.
    """

    start_date = serializers.DateField(required=False)
    end_date = serializers.DateField(required=False)
    rent = serializers.DecimalField(
        max_digits=12, decimal_places=2, min_value=0, required=False
    )
    advance = serializers.DecimalField(
        max_digits=12, decimal_places=2, min_value=0, required=False
    )
    signed_pdf_ref = serializers.CharField(
        max_length=255, required=False, allow_blank=True
    )

    def validate(self, attrs: dict[str, object]) -> dict[str, object]:
        if not attrs:
            raise serializers.ValidationError(
                "Provide at least one field to update."
            )
        start = attrs.get("start_date")
        end = attrs.get("end_date")
        if start is not None and end is not None and end < start:  # type: ignore[operator]
            raise serializers.ValidationError(
                {"end_date": "end_date must be on or after start_date."}
            )
        return attrs


class LeaseTerminateSerializer(serializers.Serializer[dict[str, object]]):
    """Validates the terminate body. ``status`` chooses ended vs. terminated.

    Defaults to ``terminated``; ``ended`` marks a natural end-of-term close.
    """

    status = serializers.ChoiceField(
        choices=[
            (LeaseStatus.ENDED.value, LeaseStatus.ENDED.label),
            (LeaseStatus.TERMINATED.value, LeaseStatus.TERMINATED.label),
        ],
        required=False,
        default=LeaseStatus.TERMINATED.value,
    )
