"""Serializers for the admin compliance endpoints — EPIC-16.T-003 / T-002.

Read-only projections for the compliance console:

* :class:`ConsentRecordSerializer` — logged consent events (T-003).
* :class:`AdminAuditEntrySerializer` — immutable admin audit log (T-002).

These records are append-only and never mutated through the API, so every
field is read-only.
"""

from __future__ import annotations

from rest_framework import serializers

from khatir.admin_portal.models import AdminAuditEntry

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


class AdminAuditEntrySerializer(serializers.ModelSerializer[AdminAuditEntry]):
    """Read-only projection of an immutable admin audit entry (EPIC-16.T-002)."""

    class Meta:
        model = AdminAuditEntry
        fields = (
            "id",
            "admin_user",
            "action",
            "entity_type",
            "entity_id",
            "before_json",
            "after_json",
            "ip",
            "reason",
            "created_at",
        )
        read_only_fields = fields
