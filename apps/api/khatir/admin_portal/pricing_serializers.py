"""Serializers for the admin-portal pricing-tier endpoints — EPIC-12.T-001.

Operations finance staff list, preview, and edit :class:`PricingTier` rows.
``PricingTierAdminSerializer`` is the full read projection (admins see prices and
the ``active``/``sort_order`` knobs the customer-facing serializer hides).
``TierPreviewSerializer`` and ``TierEditSerializer`` validate the proposed
changes; the edit body additionally requires a ``reason`` for the audit log.

All editable fields are **optional** on the request bodies — a PATCH/preview is
a partial update, so only the supplied fields are changed/previewed.
"""

from __future__ import annotations

from rest_framework import serializers

from khatir.billing.models import PricingTier

#: The tier fields an admin may edit. ``key`` is immutable (code logic depends on
#: it) and the timestamps are managed by the model — neither is editable here.
EDITABLE_TIER_FIELDS: tuple[str, ...] = (
    "label",
    "label_bn",
    "tenant_min",
    "tenant_max",
    "monthly_price",
    "annual_price",
    "includes_verification",
    "included_credits",
    "active",
    "sort_order",
)


class PricingTierAdminSerializer(serializers.ModelSerializer[PricingTier]):
    """Full read projection of a pricing tier for the admin pricing editor."""

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
            "active",
            "sort_order",
            "created_at",
            "updated_at",
        )
        read_only_fields = fields


class TierPreviewSerializer(serializers.ModelSerializer[PricingTier]):
    """Validates a *proposed* set of tier changes for the impact preview.

    Every editable field is optional (partial update); ``key`` is never accepted.
    The preview is read-only — these validated values are run through the impact
    calculation but never persisted.
    """

    class Meta:
        model = PricingTier
        fields = EDITABLE_TIER_FIELDS
        extra_kwargs = {field: {"required": False} for field in EDITABLE_TIER_FIELDS}


class TierEditSerializer(TierPreviewSerializer):
    """PATCH body: the proposed changes plus a mandatory ``reason`` for audit."""

    reason = serializers.CharField(max_length=255, trim_whitespace=True)

    class Meta(TierPreviewSerializer.Meta):
        fields = (*EDITABLE_TIER_FIELDS, "reason")

    def validate_reason(self, value: str) -> str:
        value = value.strip()
        if not value:
            raise serializers.ValidationError("A reason is required.")
        return value
