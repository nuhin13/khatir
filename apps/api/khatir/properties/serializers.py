"""DRF serializers for the buildings endpoints (T-003 §3).

Input validation only — the owner is **never** read from the client. ``owner``
is set server-side from ``request.user`` in the service layer (T-003 §15), so it
is excluded from the writable fields here. ``address`` is required; ``lat`` /
``lng`` are optional map-pin coordinates. ``ValidationError`` raised here maps to
the ``validation_error`` envelope via ``core.exceptions.exception_handler``.
"""

from __future__ import annotations

from rest_framework import serializers

from .enums import Area, UnitScheme, UnitStatus, UnitType
from .models import Building, Unit


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


class UnitSerializer(serializers.ModelSerializer[Unit]):
    """Read/serialize a unit for API responses.

    ``id`` / ``building_id`` are serialized as strings for stable client JSON;
    ``building_id`` is read-only so a client can never re-parent a unit.
    """

    id = serializers.CharField(read_only=True)
    building_id = serializers.CharField(read_only=True)

    class Meta:
        model = Unit
        fields = (
            "id",
            "building_id",
            "label",
            "type",
            "rent",
            "amenities",
            "status",
            "available_from",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "building_id", "created_at", "updated_at")


class UnitCreateSerializer(serializers.Serializer[dict[str, object]]):
    """Validates a single-unit create body. Building comes from the URL."""

    # `label` shadows DRF's ``Field.label`` attribute name; it is a real wire
    # field here, so the assignment-type mismatch the plugin reports is benign.
    label = serializers.CharField(max_length=40)  # type: ignore[assignment]
    type = serializers.ChoiceField(choices=UnitType.choices, required=False)
    rent = serializers.DecimalField(
        max_digits=12, decimal_places=2, required=False, min_value=0
    )
    amenities = serializers.ListField(
        child=serializers.CharField(), required=False
    )
    status = serializers.ChoiceField(choices=UnitStatus.choices, required=False)
    available_from = serializers.DateField(required=False, allow_null=True)


class UnitUpdateSerializer(serializers.Serializer[dict[str, object]]):
    """Validates a partial update body (PATCH). All fields optional.

    The parent building is immutable — there is no path to re-parent a unit.
    """

    # See ``UnitCreateSerializer.label`` — shadows ``Field.label`` harmlessly.
    label = serializers.CharField(max_length=40, required=False)  # type: ignore[assignment]
    type = serializers.ChoiceField(choices=UnitType.choices, required=False)
    rent = serializers.DecimalField(
        max_digits=12, decimal_places=2, required=False, min_value=0
    )
    amenities = serializers.ListField(
        child=serializers.CharField(), required=False
    )
    status = serializers.ChoiceField(choices=UnitStatus.choices, required=False)
    available_from = serializers.DateField(required=False, allow_null=True)

    def validate(self, attrs: dict[str, object]) -> dict[str, object]:
        if not attrs:
            raise serializers.ValidationError(
                "Provide at least one field to update."
            )
        return attrs


class UnitGenerateSerializer(serializers.Serializer[dict[str, object]]):
    """Validates the bulk-generate body (T-004 §7).

    ``floors`` × ``per_floor`` labels under ``scheme``, plus ``custom`` labels,
    minus ``removed``. Bounds mirror the wizard stepper (1..20) so the API and
    the UI agree on what is generatable.
    """

    floors = serializers.IntegerField(min_value=1, max_value=20)
    per_floor = serializers.IntegerField(min_value=1, max_value=20)
    scheme = serializers.ChoiceField(choices=UnitScheme.choices)
    custom = serializers.ListField(
        child=serializers.CharField(max_length=40), required=False
    )
    removed = serializers.ListField(
        child=serializers.CharField(max_length=40), required=False
    )
