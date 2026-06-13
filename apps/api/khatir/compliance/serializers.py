"""Serializers for the admin compliance endpoints — EPIC-16.T-003 / T-002 / T-004.

Read-only projections for the compliance console:

* :class:`ConsentRecordSerializer` — logged consent events (T-003).
* :class:`AdminAuditEntrySerializer` — immutable admin audit log (T-002).
* :class:`DataRequestSerializer` — PDPA export/erasure request queue (T-004).
* :class:`DataRequestProcessSerializer` — process-action body (T-004).

The log records are append-only and never mutated through the API, so every
field is read-only.
"""

from __future__ import annotations

import datetime as dt
from typing import Any

from django.conf import settings
from django.utils import timezone
from rest_framework import serializers

from khatir.admin_portal.models import AdminAuditEntry
from khatir.verification.models import VerificationLog

from .models import ConsentRecord, DataRequest


def sla_state(sla_due: dt.date) -> str:
    """Classify a request's SLA deadline relative to today.

    ``overdue`` once the deadline has passed, ``due_soon`` within
    ``DATA_REQUEST_SLA_DUE_SOON_DAYS`` days, otherwise ``on_track``.
    """
    today = timezone.now().date()
    if sla_due < today:
        return "overdue"
    soon = today + dt.timedelta(days=settings.DATA_REQUEST_SLA_DUE_SOON_DAYS)
    if sla_due <= soon:
        return "due_soon"
    return "on_track"


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

    actor = serializers.SerializerMethodField()

    class Meta:
        model = AdminAuditEntry
        fields = (
            "id",
            "admin_user",
            "actor",
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

    def get_actor(self, obj: AdminAuditEntry) -> str:
        admin = obj.admin_user
        if admin is None:
            return "System"
        return admin.name or admin.email or f"Admin #{admin.pk}"


class VerificationLogSerializer(serializers.ModelSerializer[VerificationLog]):
    """Read-only projection of a verification attempt for the compliance console.

    Surfaces **only** the boolean outcome (``result``), the date, and who
    requested it — never any raw Election Commission data. The model itself has
    no raw-EC columns; this serializer additionally never exposes the opaque
    ``provider_ref`` vendor token to the compliance viewer.
    """

    class Meta:
        model = VerificationLog
        fields = (
            "id",
            "tenant",
            "requested_by",
            "result",
            "created_at",
        )
        read_only_fields = fields


class DataRequestSerializer(serializers.ModelSerializer[DataRequest]):
    """Read-only view of a PDPA data request for the compliance queue (T-004).

    ``sla_state`` is a derived field classifying the deadline as
    ``on_track`` / ``due_soon`` / ``overdue`` (see :func:`sla_state`).
    """

    sla_state = serializers.SerializerMethodField()

    class Meta:
        model = DataRequest
        fields = (
            "id",
            "user",
            "request_type",
            "status",
            "sla_due",
            "sla_state",
            "completed_at",
            "handled_by",
            "created_at",
            "updated_at",
        )
        read_only_fields = fields

    def get_sla_state(self, obj: DataRequest) -> str:
        return sla_state(obj.sla_due)


class DataRequestProcessSerializer(serializers.Serializer[dict[str, Any]]):
    """Body for ``POST /admin/api/data-requests/{id}/process``.

    ``action`` is ``approve`` or ``reject``; ``reason`` is mandatory on a
    rejection (re-checked in the service so it can never be bypassed).
    """

    action = serializers.ChoiceField(choices=("approve", "reject"))
    reason = serializers.CharField(
        max_length=500, required=False, allow_blank=True, default=""
    )

    def validate(self, attrs: dict[str, Any]) -> dict[str, Any]:
        if attrs["action"] == "reject" and not attrs.get("reason", "").strip():
            raise serializers.ValidationError(
                {"reason": "A reason is required to reject a data request."}
            )
        return attrs


__all__ = [
    "AdminAuditEntrySerializer",
    "ConsentRecordSerializer",
    "DataRequestProcessSerializer",
    "DataRequestSerializer",
    "VerificationLogSerializer",
    "sla_state",
]
