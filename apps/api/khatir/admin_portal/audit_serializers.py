"""Serializers for the admin audit-log viewer — EPIC-11.T-011.

Read-only projection of :class:`~khatir.admin_portal.models.AdminAuditEntry`
rows for the compliance audit-log viewer. The acting admin is denormalized to a
human-readable label (email/name) so the UI never needs a second lookup, while
``before_json`` / ``after_json`` are surfaced verbatim for the diff expander.
"""

from __future__ import annotations

from rest_framework import serializers

from .models import AdminAuditEntry


class AuditLogEntrySerializer(serializers.ModelSerializer[AdminAuditEntry]):
    """A single immutable audit-log row for the compliance viewer."""

    actor = serializers.SerializerMethodField()

    class Meta:
        model = AdminAuditEntry
        fields = (
            "id",
            "action",
            "actor",
            "admin_user",
            "entity_type",
            "entity_id",
            "before_json",
            "after_json",
            "ip",
            "reason",
            "created_at",
        )
        read_only_fields = fields

    def get_actor(self, obj: AdminAuditEntry) -> str:
        """Human-readable label for the acting admin (``System`` if null)."""
        admin = obj.admin_user
        if admin is None:
            return "System"
        return admin.name or admin.email or f"Admin #{admin.pk}"
