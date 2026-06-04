"""Serializers for the admin feature-flag endpoints — EPIC-13.T-002."""

from __future__ import annotations

from rest_framework import serializers

from .models import FeatureFlag


class FeatureFlagSerializer(serializers.ModelSerializer[FeatureFlag]):
    """Read/write projection of a :class:`FeatureFlag` for the admin console.

    ``key`` is settable on create but immutable thereafter (it is the stable
    code identifier). ``enabled`` is flipped only via the dedicated ``toggle``
    endpoint, so it is read-only here; ``updated_by``/``updated_at`` are
    server-managed audit fields.
    """

    class Meta:
        model = FeatureFlag
        fields = (
            "id",
            "key",
            "description",
            "scope",
            "enabled",
            "value_json",
            "updated_by",
            "created_at",
            "updated_at",
        )
        read_only_fields = (
            "id",
            "enabled",
            "updated_by",
            "created_at",
            "updated_at",
        )

    def update(self, instance: FeatureFlag, validated_data: dict) -> FeatureFlag:
        # ``key`` is the stable identifier — never editable after creation.
        validated_data.pop("key", None)
        return super().update(instance, validated_data)
