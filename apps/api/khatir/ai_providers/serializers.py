"""Serializers for the admin AI-provider endpoints — EPIC-14.T-009.

Super/ops staff manage :class:`AIProvider` rows through the admin portal.
``AIProviderAdminSerializer`` is the read/write projection: it accepts a
plaintext ``api_key`` on write (encrypted before storage via
:func:`khatir.core.encryption.encrypt`) and **never** exposes the stored
ciphertext — only a boolean ``has_api_key`` flag, so the key is write-only.

DPA compliance rule (schema §Domain 8): a non-Bangladesh **OCR** provider
requires a ``dpa_reference`` before it can be saved. "Non-BD" is decided from
the endpoint host — anything that is not a ``.bd`` domain (including the empty
default-vendor endpoint, which resolves to a foreign cloud SDK) counts as
non-BD. The rule is enforced here at validation so both POST and PATCH are
covered.
"""

from __future__ import annotations

from typing import Any
from urllib.parse import urlparse

from rest_framework import serializers

from khatir.core.encryption import encrypt

from .enums import AICategory
from .models import AIProvider


def endpoint_is_bangladesh(endpoint_url: str) -> bool:
    """Return True only when ``endpoint_url`` is an explicit ``.bd`` domain.

    An empty endpoint (the vendor SDK default, a foreign cloud) is treated as
    non-BD, so a default-endpoint OCR provider still needs a DPA reference.
    """
    if not endpoint_url:
        return False
    host = (urlparse(endpoint_url).hostname or "").lower()
    return host == "bd" or host.endswith(".bd")


class AIProviderAdminSerializer(serializers.ModelSerializer[AIProvider]):
    """Read/write projection of an :class:`AIProvider` for the admin editor.

    ``api_key`` is write-only plaintext; it is encrypted into ``api_key_enc``
    on save and never returned. ``has_api_key`` exposes only whether a key is
    configured.
    """

    api_key = serializers.CharField(
        write_only=True,
        required=False,
        allow_blank=True,
        trim_whitespace=False,
        help_text="Plaintext API key; encrypted at rest, never returned.",
    )
    has_api_key = serializers.SerializerMethodField()

    class Meta:
        model = AIProvider
        fields = (
            "id",
            "category",
            "provider_key",
            "is_primary",
            "is_fallback",
            "model_name",
            "endpoint_url",
            "params_json",
            "dpa_reference",
            "active",
            "api_key",
            "has_api_key",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "has_api_key", "created_at", "updated_at")

    def get_has_api_key(self, obj: AIProvider) -> bool:
        return bool(obj.api_key_enc)

    def validate(self, attrs: dict[str, Any]) -> dict[str, Any]:
        """Enforce the non-BD OCR → ``dpa_reference`` compliance rule."""
        # On PATCH, fall back to the existing instance values for unsupplied fields.
        instance = self.instance
        category = attrs.get(
            "category", getattr(instance, "category", None)
        )
        endpoint_url = attrs.get(
            "endpoint_url", getattr(instance, "endpoint_url", "")
        )
        dpa_reference = attrs.get(
            "dpa_reference", getattr(instance, "dpa_reference", "")
        )

        if (
            category == AICategory.OCR
            and not endpoint_is_bangladesh(endpoint_url)
            and not (dpa_reference or "").strip()
        ):
            raise serializers.ValidationError(
                {
                    "dpa_reference": (
                        "A DPA reference is required for a non-Bangladesh OCR "
                        "provider before it can be saved."
                    )
                }
            )
        return attrs

    def _apply_api_key(self, validated_data: dict[str, Any]) -> None:
        """Pop a supplied plaintext ``api_key`` and store its ciphertext."""
        if "api_key" in validated_data:
            plaintext = validated_data.pop("api_key")
            validated_data["api_key_enc"] = encrypt(plaintext) if plaintext else ""

    def create(self, validated_data: dict[str, Any]) -> AIProvider:
        self._apply_api_key(validated_data)
        return super().create(validated_data)

    def update(self, instance: AIProvider, validated_data: dict[str, Any]) -> AIProvider:
        self._apply_api_key(validated_data)
        return super().update(instance, validated_data)
