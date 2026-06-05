"""DRF serializers for the caretaker-assignment endpoints (T-002 §3).

Input validation only — the building comes from the scoped URL and ``assigned_by``
is set server-side from ``request.user`` (never trusted from the client). The
create body carries just the ``caretaker_id`` of the User to assign; resolving
that id to a caretaker User (and the role check) happens in the service layer.
``ValidationError`` raised here maps to the ``validation_error`` envelope via
``core.exceptions.exception_handler``.
"""

from __future__ import annotations

from rest_framework import serializers

from .models import CaretakerAssignment


class CaretakerAssignmentSerializer(serializers.ModelSerializer[CaretakerAssignment]):
    """Read/serialize a caretaker assignment for API responses.

    Ids are serialized as strings for stable JSON handling on the client; every
    relational field and the audited ``assigned_by`` are read-only so a client
    can never set them.
    """

    id = serializers.CharField(read_only=True)
    caretaker_id = serializers.CharField(read_only=True)
    building_id = serializers.CharField(read_only=True)
    assigned_by_id = serializers.CharField(read_only=True)

    class Meta:
        model = CaretakerAssignment
        fields = (
            "id",
            "caretaker_id",
            "building_id",
            "assigned_by_id",
            "status",
            "created_at",
            "updated_at",
        )
        read_only_fields = fields


class CaretakerAssignmentCreateSerializer(serializers.Serializer[dict[str, object]]):
    """Validates an assign body: the id of the caretaker User to assign.

    The building is taken from the URL and ``assigned_by`` from ``request.user``;
    only the caretaker id is client-supplied. Whether the id resolves to a real
    caretaker User is enforced in the service (so the error is a typed
    ``validation_error``/``not_found`` rather than a serializer field error).
    """

    caretaker_id = serializers.CharField()
