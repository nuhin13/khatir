"""DRF serializers for the maintenance endpoints (T-002 §3/§7).

Input validation only. The ``unit`` is supplied by id and resolved+scoped in the
service (the landlord/owner is never trusted from the client). The read
serializer exposes the resolved ids as strings and is fully read-only so a
client can never re-parent a request or set its status/resolution directly —
those are server-driven through the resolve action.
"""

from __future__ import annotations

from rest_framework import serializers

from .enums import ExpenseCategory, MaintenanceCategory
from .models import Expense, MaintenanceRequest


class MaintenanceRequestSerializer(serializers.ModelSerializer[MaintenanceRequest]):
    """Read/serialize a maintenance request for API responses.

    Ids are serialized as strings for stable client JSON; status and resolution
    fields are read-only (set only by the resolve action, never the client).
    """

    id = serializers.CharField(read_only=True)
    unit_id = serializers.CharField(read_only=True)
    lease_id = serializers.CharField(read_only=True, allow_null=True)

    class Meta:
        model = MaintenanceRequest
        fields = (
            "id",
            "unit_id",
            "lease_id",
            "category",
            "description",
            "photo_ref",
            "status",
            "resolved_at",
            "resolution_cost",
            "resolution_note",
            "created_at",
            "updated_at",
        )
        read_only_fields = fields


class ExpenseSerializer(serializers.ModelSerializer[Expense]):
    """Read/serialize an expense row (auto-created on resolve or logged manually)."""

    id = serializers.CharField(read_only=True)
    unit_id = serializers.CharField(read_only=True)
    request_id = serializers.CharField(read_only=True, allow_null=True)

    class Meta:
        model = Expense
        fields = (
            "id",
            "unit_id",
            "request_id",
            "category",
            "amount",
            "date",
            "source",
            "note",
            "receipt_ref",
            "created_at",
            "updated_at",
        )
        read_only_fields = fields


class ExpenseCreateSerializer(serializers.Serializer[dict[str, object]]):
    """Validates a manual-expense create body (T-003 §2).

    The ``unit`` is supplied by id and resolved+scoped server-side; ``source`` is
    forced to ``manual`` in the service (never client-settable — auto-expenses
    come from the resolve action, not this endpoint). Money is a ``Decimal``.
    """

    unit_id = serializers.CharField()
    amount = serializers.DecimalField(max_digits=12, decimal_places=2, min_value=0)
    date = serializers.DateField()
    category = serializers.ChoiceField(
        choices=ExpenseCategory.choices,
        required=False,
        default=ExpenseCategory.OTHER.value,
    )
    note = serializers.CharField(required=False, allow_blank=True, default="")
    receipt_ref = serializers.CharField(
        max_length=255, required=False, allow_blank=True, default=""
    )


class ExpenseUpdateSerializer(serializers.Serializer[dict[str, object]]):
    """Validates a partial update body (PATCH) for a manual expense.

    All fields optional; ``unit``/``source``/``request`` are immutable here. An
    auto-expense (``source=request``) is not editable through this endpoint
    (enforced in the service).
    """

    amount = serializers.DecimalField(
        max_digits=12, decimal_places=2, min_value=0, required=False
    )
    date = serializers.DateField(required=False)
    category = serializers.ChoiceField(choices=ExpenseCategory.choices, required=False)
    note = serializers.CharField(required=False, allow_blank=True)
    receipt_ref = serializers.CharField(
        max_length=255, required=False, allow_blank=True
    )

    def validate(self, attrs: dict[str, object]) -> dict[str, object]:
        if not attrs:
            raise serializers.ValidationError("Provide at least one field to update.")
        return attrs


class MaintenanceRequestCreateSerializer(serializers.Serializer[dict[str, object]]):
    """Validates a create body. Unit is resolved+scoped server-side by id.

    The request is always created ``open`` (status is not client-settable);
    resolution is a separate action.
    """

    unit_id = serializers.CharField()
    description = serializers.CharField()
    category = serializers.ChoiceField(
        choices=MaintenanceCategory.choices,
        required=False,
        default=MaintenanceCategory.OTHER.value,
    )
    photo_ref = serializers.CharField(
        max_length=255, required=False, allow_blank=True, default=""
    )
    lease_id = serializers.CharField(required=False, allow_null=True, default=None)


class MaintenanceRequestUpdateSerializer(serializers.Serializer[dict[str, object]]):
    """Validates a partial update body (PATCH). All fields optional.

    Only the descriptive fields are editable, and only while the request is open
    (enforced in the service). Unit and status are immutable here.
    """

    description = serializers.CharField(required=False)
    category = serializers.ChoiceField(
        choices=MaintenanceCategory.choices, required=False
    )
    photo_ref = serializers.CharField(
        max_length=255, required=False, allow_blank=True
    )

    def validate(self, attrs: dict[str, object]) -> dict[str, object]:
        if not attrs:
            raise serializers.ValidationError("Provide at least one field to update.")
        return attrs


class MaintenanceResolveSerializer(serializers.Serializer[dict[str, object]]):
    """Validates the resolve body: the cost that becomes the auto-expense."""

    cost = serializers.DecimalField(max_digits=12, decimal_places=2, min_value=0)
    note = serializers.CharField(required=False, allow_blank=True, default="")
