"""DRF serializers for the rent-request endpoints (T-003 §3).

Input validation only — the owner/landlord is **never** read from the client; it
is derived server-side from the request's lease. A request is created either from
a scheduled month (``rent_schedule`` supplied — amount/period are taken from the
schedule) or as a manual one-off (``lease`` + ``amount`` + ``period`` supplied,
``rent_schedule`` null). ``ValidationError`` raised here maps to the
``validation_error`` envelope via ``core.exceptions.exception_handler``.
"""

from __future__ import annotations

from rest_framework import serializers

from .enums import Channel
from .models import RentRequest


class RentRequestSerializer(serializers.ModelSerializer[RentRequest]):
    """Read/serialize a rent request for API responses.

    Ids are serialized as strings for stable client JSON; the lease/schedule
    links and the issued ``link_token`` are read-only (a client can never set
    them — the token is minted server-side by the T-002 service).
    """

    id = serializers.CharField(read_only=True)
    lease_id = serializers.CharField(read_only=True)
    rent_schedule_id = serializers.CharField(read_only=True, allow_null=True)

    class Meta:
        model = RentRequest
        fields = (
            "id",
            "lease_id",
            "rent_schedule_id",
            "amount",
            "period",
            "link_token",
            "sent_via",
            "sent_at",
            "status",
            "created_at",
            "updated_at",
        )
        read_only_fields = fields


class RentRequestCreateSerializer(serializers.Serializer[dict[str, object]]):
    """Validates a create body.

    Two shapes are accepted:

    - **From a schedule** — supply ``rent_schedule`` (the lease, amount and
      period are derived from it; any ``lease``/``amount``/``period`` sent
      alongside is ignored).
    - **Manual one-off** — supply ``lease`` plus ``amount`` and ``period``;
      ``rent_schedule`` is left null.

    Exactly one of ``rent_schedule`` / ``lease`` must be given.
    """

    rent_schedule = serializers.IntegerField(required=False, allow_null=True)
    lease = serializers.IntegerField(required=False, allow_null=True)
    amount = serializers.DecimalField(
        max_digits=12, decimal_places=2, required=False, min_value=0
    )
    period = serializers.RegexField(
        r"^\d{4}-\d{2}$", required=False, error_messages={"invalid": "period must be YYYY-MM."}
    )
    sent_via = serializers.ChoiceField(
        choices=Channel.choices, required=False, default=Channel.WHATSAPP
    )

    def validate(self, attrs: dict[str, object]) -> dict[str, object]:
        schedule_id = attrs.get("rent_schedule")
        lease_id = attrs.get("lease")
        if not schedule_id and not lease_id:
            raise serializers.ValidationError(
                "Provide either `rent_schedule` (from a schedule) or `lease` "
                "(manual one-off)."
            )
        if schedule_id and lease_id:
            raise serializers.ValidationError(
                "Provide either `rent_schedule` or `lease`, not both."
            )
        if lease_id and not (attrs.get("amount") is not None and attrs.get("period")):
            raise serializers.ValidationError(
                "A manual request requires both `amount` and `period`."
            )
        return attrs
