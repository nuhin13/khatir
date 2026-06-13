"""DRF serializers for the billing endpoints (T-004 §3).

``SubscriptionSerializer`` is the read shape for ``GET /billing/subscription`` —
it carries the current plan, billing dates, status, and the caller's tenant
usage (used / limit) so the plan screen can render "3 / 10 tenants" without a
second round-trip. ``SubscribeSerializer`` validates the create/upgrade body —
just the ``tier_key`` plus an optional billing cycle; the service resolves the
tier and stamps the dates (the client never sends prices or dates).
"""

from __future__ import annotations

from rest_framework import serializers

from .enums import BillingCycle
from .models import PricingTier, Subscription


class TierSerializer(serializers.ModelSerializer[PricingTier]):
    """Read-only nested plan summary embedded in a subscription response."""

    id = serializers.CharField(read_only=True)

    class Meta:
        model = PricingTier
        fields = (
            "id",
            "key",
            "label",
            "label_bn",
            "tenant_min",
            "tenant_max",
            "monthly_price",
            "annual_price",
            "includes_verification",
            "included_credits",
        )
        read_only_fields = fields


class SubscriptionSerializer(serializers.ModelSerializer[Subscription]):
    """Read shape for ``GET /billing/subscription`` — plan + usage.

    ``tenants_used`` / ``tenants_limit`` are injected by the view from the
    tenant-usage selector (``tenants_limit = None`` means unlimited). They are
    not model fields, so they are declared as plain read-only fields and
    populated through the serializer context.
    """

    id = serializers.CharField(read_only=True)
    tier = TierSerializer(read_only=True)
    tenants_used = serializers.SerializerMethodField()
    tenants_limit = serializers.SerializerMethodField()

    class Meta:
        model = Subscription
        fields = (
            "id",
            "tier",
            "billing_cycle",
            "status",
            "start_at",
            "next_billing_at",
            "tenants_used",
            "tenants_limit",
            "created_at",
            "updated_at",
        )
        read_only_fields = fields

    def get_tenants_used(self, obj: Subscription) -> int:
        return int(self.context.get("tenants_used", 0))

    def get_tenants_limit(self, obj: Subscription) -> int | None:
        return self.context.get("tenants_limit")


class SubscribeSerializer(serializers.Serializer[dict[str, object]]):
    """Validates the ``POST /billing/subscribe`` body.

    Only ``tier_key`` (and an optional ``billing_cycle``) are accepted — the
    service resolves the tier, rejecting an unknown/inactive one, and computes
    the billing dates. Prices and dates are never client-supplied.
    """

    tier_key = serializers.CharField(max_length=64)
    billing_cycle = serializers.ChoiceField(
        choices=BillingCycle.choices,
        required=False,
        default=BillingCycle.MONTHLY,
    )
