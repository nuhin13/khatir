"""Serializers for the DMP form endpoints (EPIC-05 T-005 §7).

``DMPFormRecordSerializer`` is the read shape of a generated record — it exposes
the opaque ``pdf_ref`` and metadata but **never** any field payload or NID.
``GeneratePdfResponseSerializer`` documents the generate response (record +
signed URL) for the OpenAPI schema.
"""

from __future__ import annotations

from rest_framework import serializers

from .models import DMPFormRecord


class DMPFormRecordSerializer(serializers.ModelSerializer[DMPFormRecord]):
    """Read serializer for a generated DMP form record."""

    class Meta:
        model = DMPFormRecord
        fields = (
            "id",
            "tenant",
            "template_version",
            "pdf_ref",
            "generated_by",
            "generated_at",
            "created_at",
        )
        read_only_fields = fields


class GeneratePdfResponseSerializer(serializers.Serializer):  # type: ignore[type-arg]
    """Response of ``POST …/dmpform/pdf``: the record plus a signed download URL."""

    record = DMPFormRecordSerializer()
    signed_url = serializers.URLField()
