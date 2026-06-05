"""DRF serializers for the manager owner-link endpoints (EPIC-22 · T-003 §3).

- :class:`OwnerLinkRequestSerializer` validates a manager's link request input
  (the owner to link and an optional permissions scope).
- :class:`OwnerLinkConsentSerializer` validates the owner's accept/decline.
- :class:`ManagerOwnerLinkSerializer` shapes a link for the read responses.
"""

from __future__ import annotations

from rest_framework import serializers

from .models import ManagerOwnerLink


class OwnerLinkRequestSerializer(serializers.Serializer):
    """Input for ``POST /api/v1/manager/owners`` — request an owner link."""

    owner_id = serializers.IntegerField(min_value=1)
    permissions_scope = serializers.ListField(
        child=serializers.CharField(),
        required=False,
        default=list,
        allow_empty=True,
    )


class OwnerLinkConsentSerializer(serializers.Serializer):
    """Input for the owner consent endpoint — ``accept`` true/false."""

    accept = serializers.BooleanField()


class ManagerOwnerLinkSerializer(serializers.ModelSerializer):
    """Read shape for a manager-owner link."""

    owner_name = serializers.CharField(source="owner.name", read_only=True)

    class Meta:
        model = ManagerOwnerLink
        fields = (
            "id",
            "manager",
            "owner",
            "owner_name",
            "status",
            "permissions_scope",
            "created_at",
            "updated_at",
        )
        read_only_fields = fields
