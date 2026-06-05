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

# Cap on an inline-uploaded proof screenshot (bytes). Mirrors the web-link page
# (EPIC-07 T-006): proof screenshots are phone captures, so anything larger is
# almost certainly abuse and is rejected up front.
_MAX_SCREENSHOT_BYTES = 8 * 1024 * 1024  # 8 MiB


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


class InAppProofSerializer(serializers.Serializer[dict[str, object]]):
    """Validate an in-app payment-proof body (``POST /me/rent/{id}/pay``, T-003).

    The in-app counterpart of the web-link proof form (EPIC-07 T-006): a tenant
    submits a bKash/Nagad transaction id, a free-text note, or a screenshot
    upload. At least one usable field is required. The view feeds the validated
    fields into the **same** ``submit_payment_proof`` pipeline — no new proof
    logic here.
    """

    txn_id = serializers.CharField(
        max_length=255, required=False, allow_blank=True, trim_whitespace=True
    )
    note = serializers.CharField(
        max_length=255, required=False, allow_blank=True, trim_whitespace=True
    )
    screenshot = serializers.FileField(required=False)

    def validate_screenshot(self, value: object) -> object:
        size = getattr(value, "size", 0)
        if size and size > _MAX_SCREENSHOT_BYTES:
            raise serializers.ValidationError("Screenshot is too large (max 8 MiB).")
        return value

    def validate(self, attrs: dict[str, object]) -> dict[str, object]:
        if not (attrs.get("txn_id") or attrs.get("note") or attrs.get("screenshot")):
            raise serializers.ValidationError(
                "Provide a `txn_id`, a `note`, or a `screenshot`."
            )
        return attrs
