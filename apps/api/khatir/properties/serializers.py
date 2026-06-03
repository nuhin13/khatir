"""DRF serializers for the buildings endpoints (T-003 §3).

Input validation only — the owner is **never** read from the client. ``owner``
is set server-side from ``request.user`` in the service layer (T-003 §15), so it
is excluded from the writable fields here. ``address`` is required; ``lat`` /
``lng`` are optional map-pin coordinates. ``ValidationError`` raised here maps to
the ``validation_error`` envelope via ``core.exceptions.exception_handler``.
"""

from __future__ import annotations

from rest_framework import serializers

from .enums import Area
from .models import Building


class BuildingSerializer(serializers.ModelSerializer[Building]):
    """Read/serialize a building for API responses.

    ``id`` is serialized as a string for stable JSON handling on the client; the
    owner is exposed read-only as ``owner_id`` so a client can never set it.
    """

    id = serializers.CharField(read_only=True)
    owner_id = serializers.CharField(read_only=True)

    class Meta:
        model = Building
        fields = (
            "id",
            "owner_id",
            "name",
            "area",
            "address",
            "lat",
            "lng",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "owner_id", "created_at", "updated_at")


class BuildingCreateSerializer(serializers.Serializer[dict[str, object]]):
    """Validates a create body. Owner is set server-side, never from the client."""

    name = serializers.CharField(max_length=120)
    area = serializers.ChoiceField(choices=Area.choices)
    address = serializers.CharField()
    lat = serializers.DecimalField(
        max_digits=9, decimal_places=6, required=False, allow_null=True
    )
    lng = serializers.DecimalField(
        max_digits=9, decimal_places=6, required=False, allow_null=True
    )


class BuildingUpdateSerializer(serializers.Serializer[dict[str, object]]):
    """Validates a partial update body (PATCH). All fields optional.

    Owner is immutable — there is no path to reassign a building to another user.
    """

    name = serializers.CharField(max_length=120, required=False)
    area = serializers.ChoiceField(choices=Area.choices, required=False)
    address = serializers.CharField(required=False)
    lat = serializers.DecimalField(
        max_digits=9, decimal_places=6, required=False, allow_null=True
    )
    lng = serializers.DecimalField(
        max_digits=9, decimal_places=6, required=False, allow_null=True
    )

    def validate(self, attrs: dict[str, object]) -> dict[str, object]:
        if not attrs:
            raise serializers.ValidationError(
                "Provide at least one field to update."
            )
        return attrs
