"""DRF serializers for the warnings endpoints (T-002 §3).

Reads expose the private warning fields for the issuing landlord only (scope is
enforced upstream by ``Warning.objects.for_user``). Writes accept only the two
client-supplied fields — ``warning_type`` and ``reason``; the lease, tenant and
landlord are derived server-side from the URL lease + ``request.user`` so a
client can never forge a cross-landlord warning. ``id`` columns serialize as
strings for stable client JSON.
"""

from __future__ import annotations

from rest_framework import serializers

from .enums import WarningType
from .models import Warning


class WarningSerializer(serializers.ModelSerializer[Warning]):
    """Read serializer for a single private warning."""

    id = serializers.CharField(read_only=True)
    lease = serializers.CharField(source="lease_id", read_only=True)
    tenant = serializers.CharField(source="tenant_id", read_only=True)
    landlord = serializers.CharField(source="landlord_id", read_only=True)

    class Meta:
        model = Warning
        fields = (
            "id",
            "lease",
            "tenant",
            "landlord",
            "warning_type",
            "reason",
            "issued_at",
            "notice_ref",
            "acknowledged_at",
        )
        read_only_fields = fields


class WarningCreateSerializer(serializers.Serializer[Warning]):
    """Write serializer for issuing a warning — only the client-supplied fields.

    The lease/tenant/landlord are never accepted from the client; they are
    resolved server-side from the URL lease scope and ``request.user``.
    """

    warning_type = serializers.ChoiceField(
        choices=WarningType.choices, default=WarningType.OTHER
    )
    reason = serializers.CharField(allow_blank=False, trim_whitespace=True)
