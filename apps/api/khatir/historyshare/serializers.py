"""Serializers for the tenant-initiated history-share endpoints (EPIC-24.T-002).

The request serializer validates the tenant's input only — the acting tenant is
NEVER read from the body (it is resolved from ``request.user`` in the service),
so a tenant can never forge a share on someone else's behalf. The recipient must
be an existing landlord-role user; any other id is rejected as invalid input
(not 404 — the field is part of the request payload).

The response serializer surfaces the FACTUAL snapshot and lifecycle fields only.
There is structurally no subjective field to leak.
"""

from __future__ import annotations

from rest_framework import serializers

from khatir.accounts.enums import Role
from khatir.accounts.models import User

from .models import HistoryShare


class HistoryShareCreateSerializer(serializers.Serializer[dict[str, object]]):
    """Validate a tenant's request to create a share.

    * ``recipient_landlord`` — the landlord user id to share with (required).
    * ``scope`` — optional tenant-selected scope selector (counts/booleans
      only; never subjective data).
    * ``expires_at`` — optional expiry; the view/service reject a past value.
    """

    recipient_landlord = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.filter(role=Role.LANDLORD),
        help_text="The prospective landlord to share with. Must be a landlord.",
    )
    scope = serializers.JSONField(required=False, default=dict)
    expires_at = serializers.DateTimeField(required=False, allow_null=True)


class HistoryShareSerializer(serializers.ModelSerializer[HistoryShare]):
    """Read representation of a created share — factual fields only."""

    class Meta:
        model = HistoryShare
        fields = [
            "id",
            "token",
            "tenant",
            "recipient_landlord",
            "scope",
            "consent_record",
            "factual_stats",
            "expires_at",
            "revoked_at",
            "created_at",
        ]
        read_only_fields = fields


class HistoryShareOwnerSerializer(serializers.ModelSerializer[HistoryShare]):
    """Owner-facing (tenant transparency) view of a share — EPIC-24.T-004.

    Surfaces WHAT was shared (``scope``, ``factual_stats``), WHO it went to
    (``recipient_landlord``), WHEN (``created_at``, ``expires_at``,
    ``revoked_at``) and its lifecycle ``status`` (active / expired / revoked).
    This is the only place the OWNING tenant sees their own lifecycle state;
    the recipient read view (T-003) never exposes any of it. Read-only — the
    only mutation a tenant can make is the explicit ``revoke`` action.
    """

    status = serializers.SerializerMethodField()

    class Meta:
        model = HistoryShare
        fields = [
            "id",
            "recipient_landlord",
            "scope",
            "factual_stats",
            "status",
            "expires_at",
            "revoked_at",
            "created_at",
        ]
        read_only_fields = fields

    def get_status(self, obj: HistoryShare) -> str:
        return obj.status()


class HistoryShareRecipientSerializer(serializers.ModelSerializer[HistoryShare]):
    """Recipient-facing read view of an ACTIVE share — factual stats ONLY.

    Surfaces the frozen factual snapshot, the tenant-selected ``scope`` and the
    expiry, and nothing that identifies internal records (no internal id, no
    consent_record id, no recipient id). There is structurally no subjective
    field to leak. Read-only by construction — no write/export path exists.
    """

    class Meta:
        model = HistoryShare
        fields = [
            "token",
            "scope",
            "factual_stats",
            "expires_at",
            "created_at",
        ]
        read_only_fields = fields
