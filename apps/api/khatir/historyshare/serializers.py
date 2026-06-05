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
