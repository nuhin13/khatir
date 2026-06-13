"""Serializers for the gov-export endpoints (EPIC-26 T-004 §1).

``GovExportSerializer`` is the read shape of a ledger row — it exposes the
opaque ``file_ref`` and metadata but never any tenant payload or NID.
``GenerateExportRequestSerializer`` validates the generate body (the ``period``
the package covers). ``GenerateExportResponseSerializer`` documents the generate
response (the ledger row plus a signed download URL) for the OpenAPI schema.
"""

from __future__ import annotations

import re

from rest_framework import serializers

from .models import GovExport

#: A period is a calendar month ``YYYY-MM`` (matches ``GovExport.period``).
_PERIOD_RE = re.compile(r"^\d{4}-(0[1-9]|1[0-2])$")


class GovExportSerializer(serializers.ModelSerializer[GovExport]):
    """Read serializer for a generated gov-export ledger row."""

    class Meta:
        model = GovExport
        fields = (
            "id",
            "landlord",
            "period",
            "format_version",
            "file_ref",
            "record_count",
            "status",
            "created_at",
        )
        read_only_fields = fields


class GenerateExportRequestSerializer(serializers.Serializer):  # type: ignore[type-arg]
    """Validates the generate body: the ``YYYY-MM`` period to export."""

    period = serializers.CharField(max_length=7)

    def validate_period(self, value: str) -> str:
        if not _PERIOD_RE.match(value):
            raise serializers.ValidationError(
                "period must be a calendar month in 'YYYY-MM' format."
            )
        return value


class GenerateExportResponseSerializer(serializers.Serializer):  # type: ignore[type-arg]
    """Response of ``POST /gov-export``: the ledger row plus a signed URL."""

    export = GovExportSerializer()
    signed_url = serializers.URLField()
