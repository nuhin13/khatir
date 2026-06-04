"""Serializers for the admin compliance endpoints — EPIC-16.T-003.

Read-only projection of :class:`ConsentRecord` for the compliance console.
Consent records are append-only and never mutated through the API, so every
field is read-only.
"""

from __future__ import annotations

from rest_framework import serializers

from .models import ConsentRecord


class ConsentRecordSerializer(serializers.ModelSerializer[ConsentRecord]):
    """Read-only view of a logged consent event for the admin console."""

    class Meta:
        model = ConsentRecord
        fields = (
            "id",
            "user",
            "consent_type",
            "granted_at",
            "revoked_at",
            "expires_at",
            "created_at",
            "updated_at",
        )
        read_only_fields = fields
