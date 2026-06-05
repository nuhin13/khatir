"""Read serializers for the tenant self-service ``/api/v1/me/`` surface (T-002).

All three are **read-only** — the tenant endpoints expose existing rows
(leases, rent schedules + requests, confirmed payments) and never accept a
write. They reuse the existing domain serializers where one already fits
(``LeaseSerializer``, ``RentScheduleSerializer``, ``RentRequestSerializer``)
and add only what the rent app has not already serialized: a compact receipt
view over a confirmed :class:`~khatir.rent.models.Payment`.

Ids are serialized as strings for stable client JSON, matching the convention
used across the leases/rent serializers.
"""

from __future__ import annotations

from rest_framework import serializers

from khatir.rent.models import Payment


class ReceiptSerializer(serializers.ModelSerializer[Payment]):
    """A confirmed payment as a tenant-facing receipt (``/api/v1/me/receipts``).

    A receipt *is* a verified :class:`Payment`: it carries the pointer to the
    generated receipt PDF (``receipt_ref``) plus the period/amount of the rent
    request it settled, so the tenant's receipts list needs no extra round-trip
    to label each row. Read-only — the tenant never creates a payment; the
    landlord's verify flow (EPIC-07 T-007) does.
    """

    id = serializers.CharField(read_only=True)
    rent_request_id = serializers.CharField(read_only=True)
    lease_id = serializers.CharField(source="rent_request.lease_id", read_only=True)
    period = serializers.CharField(source="rent_request.period", read_only=True)
    amount = serializers.DecimalField(
        source="rent_request.amount",
        max_digits=12,
        decimal_places=2,
        read_only=True,
    )

    class Meta:
        model = Payment
        fields = (
            "id",
            "rent_request_id",
            "lease_id",
            "period",
            "amount",
            "receipt_ref",
            "verified_at",
            "created_at",
            "updated_at",
        )
        read_only_fields = fields
