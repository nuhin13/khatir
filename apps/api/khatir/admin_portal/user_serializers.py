"""Serializers for the admin-portal user management endpoints — EPIC-12.T-003.

Projections of the customer-facing ``accounts.User`` (plus their current
subscription, usage counters, and recent admin audit trail) for operations
staff, and request bodies for the suspend / reactivate / upgrade actions.

These are *read* projections of customer data exposed to admins — they never
leak secrets (the raw phone is masked, NIDs are only ever the masked form).
"""

from __future__ import annotations

from rest_framework import serializers

from khatir.accounts.models import User
from khatir.admin_portal.models import AdminAuditEntry
from khatir.billing.models import Subscription


class AdminUserListSerializer(serializers.ModelSerializer[User]):
    """Compact row projection for the user search list."""

    masked_phone = serializers.CharField(read_only=True)

    class Meta:
        model = User
        fields = (
            "id",
            "name",
            "phone",
            "masked_phone",
            "role",
            "language",
            "is_active",
            "last_login_at",
            "created_at",
        )
        read_only_fields = fields


class AdminSubscriptionSerializer(serializers.ModelSerializer[Subscription]):
    """A user's current subscription as shown on the admin detail page."""

    tier_key = serializers.CharField(source="tier.key", read_only=True)
    tier_label = serializers.CharField(source="tier.label", read_only=True)

    class Meta:
        model = Subscription
        fields = (
            "id",
            "tier",
            "tier_key",
            "tier_label",
            "billing_cycle",
            "status",
            "start_at",
            "next_billing_at",
        )
        read_only_fields = fields


class AdminAuditTrailSerializer(serializers.ModelSerializer[AdminAuditEntry]):
    """A single audit-trail row in a user's recent admin-action history."""

    class Meta:
        model = AdminAuditEntry
        fields = (
            "id",
            "action",
            "admin_user",
            "reason",
            "before_json",
            "after_json",
            "created_at",
        )
        read_only_fields = fields


class AdminSuspendUserSerializer(serializers.Serializer[dict[str, str]]):
    """``POST /admin/api/users/{id}/suspend`` body — ``reason`` is mandatory."""

    reason = serializers.CharField(max_length=255, trim_whitespace=True)

    def validate_reason(self, value: str) -> str:
        value = value.strip()
        if not value:
            raise serializers.ValidationError("A suspension reason is required.")
        return value


class AdminReactivateUserSerializer(serializers.Serializer[dict[str, str]]):
    """``POST /admin/api/users/{id}/reactivate`` body — optional reason."""

    reason = serializers.CharField(
        max_length=255, required=False, allow_blank=True, default=""
    )


class AdminUpgradeSubscriptionSerializer(serializers.Serializer[dict[str, object]]):
    """``POST /admin/api/users/{id}/upgrade-subscription`` body.

    Manual operations override: move the user onto ``tier_id`` (and optionally a
    different ``billing_cycle``), with a mandatory ``reason`` for the audit log.
    """

    tier_id = serializers.IntegerField()
    billing_cycle = serializers.CharField(required=False, allow_blank=True, default="")
    reason = serializers.CharField(max_length=255, trim_whitespace=True)

    def validate_reason(self, value: str) -> str:
        value = value.strip()
        if not value:
            raise serializers.ValidationError("A reason is required.")
        return value
