"""Verification API serializers — boolean-only result (EPIC-17 T-004 §7).

The verify / last-verification endpoints return a deliberately minimal payload:
``{result, date}``. There is **no** raw-EC field and **no** NID — only the boolean
outcome and the timestamp the attempt was logged. ``provider_ref`` is an internal
audit handle and is intentionally not serialized to clients.
"""

from __future__ import annotations

from rest_framework import serializers

from .models import VerificationLog


class VerificationResultSerializer(serializers.ModelSerializer[VerificationLog]):
    """Serialize a :class:`VerificationLog` as ``{result, date}`` (boolean-only)."""

    date = serializers.DateTimeField(source="created_at", read_only=True)

    class Meta:
        model = VerificationLog
        fields = ("result", "date")
        read_only_fields = fields
