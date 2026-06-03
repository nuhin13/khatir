"""AI providers domain models — Domain 8 of ``06_database_schema.md``.

``AIProvider`` holds the configuration for a single AI vendor per category
(chat/voice/ocr/lease).  The API key is **encrypted** at rest using
``khatir.core.encryption`` — never store or log the plaintext.  A
``dpa_reference`` is required before a non-BD OCR provider can be activated
(compliance rule from the schema).

``AIUsageLog`` captures per-call usage metrics for every AI call, including
optional ``failover_from`` tracking when a fallback provider was used.

Both models use ``TimeStampedModel`` (not ``SoftDeleteModel``) because they are
catalogue / ledger rows that the schema does not soft-delete.
"""

from __future__ import annotations

from django.db import models

from khatir.core.models import TimeStampedModel

from .enums import AICategory


class AIProvider(TimeStampedModel):
    """A configurable AI vendor for a specific capability category.

    ``api_key_enc`` stores the Fernet-encrypted form of the API key produced by
    ``khatir.core.encryption.encrypt()``.  Call ``core.encryption.decrypt()``
    to retrieve the plaintext — only at call time, never logged.
    """

    category = models.CharField(
        max_length=8,
        choices=AICategory.choices,
        help_text="Capability category: chat / voice / ocr / lease.",
    )
    provider_key = models.CharField(
        max_length=64,
        help_text="Stable vendor identifier, e.g. 'openai', 'google_vision'.",
    )
    is_primary = models.BooleanField(
        default=False,
        help_text="True if this is the primary provider for its category.",
    )
    is_fallback = models.BooleanField(
        default=False,
        help_text="True if this provider is used as a fallback.",
    )
    model_name = models.CharField(
        max_length=128,
        blank=True,
        default="",
        help_text="Model identifier, e.g. 'gpt-4o', 'gemini-2.0-flash'.",
    )
    api_key_enc = models.TextField(
        blank=True,
        default="",
        help_text=(
            "Fernet-encrypted API key (from khatir.core.encryption.encrypt). "
            "Never store or log the plaintext."
        ),
    )
    endpoint_url = models.URLField(
        max_length=255,
        blank=True,
        default="",
        help_text="Override endpoint URL; empty means the SDK default.",
    )
    params_json = models.JSONField(
        null=True,
        blank=True,
        default=None,
        help_text="Extra provider-specific parameters (temperature, timeout, etc.).",
    )
    dpa_reference = models.CharField(
        max_length=255,
        blank=True,
        default="",
        help_text=(
            "Data Processing Agreement reference number. Required before activating "
            "a non-BD OCR provider (compliance rule)."
        ),
    )
    active = models.BooleanField(
        default=True,
        help_text="Inactive providers are skipped by the AI routing layer.",
    )

    class Meta:
        verbose_name = "AI provider"
        verbose_name_plural = "AI providers"
        ordering = ("category", "provider_key")
        indexes = [
            models.Index(fields=["category", "is_primary"]),
            models.Index(fields=["category", "active"]),
        ]

    def __str__(self) -> str:
        flag = "primary" if self.is_primary else ("fallback" if self.is_fallback else "inactive")
        return f"{self.provider_key} [{self.category}] ({flag})"


class AIUsageLog(TimeStampedModel):
    """A per-call usage record for every AI provider invocation.

    ``failover_from`` is set when a fallback provider handled the call —
    it points to the primary provider that failed.  ``cost_usd`` is a
    ``Decimal(12,2)`` in US dollars as reported by the upstream vendor.
    """

    provider = models.ForeignKey(
        AIProvider,
        on_delete=models.PROTECT,
        related_name="usage_logs",
        help_text="The provider that handled this call.",
    )
    category = models.CharField(
        max_length=8,
        choices=AICategory.choices,
        help_text="Denormalised category for direct log queries.",
    )
    request_count = models.PositiveIntegerField(
        default=1,
        help_text="Number of API requests aggregated into this log row.",
    )
    tokens_used = models.PositiveIntegerField(
        default=0,
        help_text="Total tokens consumed (prompt + completion where applicable).",
    )
    cost_usd = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=0,
        help_text="Vendor-reported cost in USD for this call.",
    )
    success = models.BooleanField(
        default=True,
        help_text="False if the call failed or returned an error response.",
    )
    latency_ms = models.PositiveIntegerField(
        default=0,
        help_text="Round-trip latency in milliseconds.",
    )
    failover_from = models.ForeignKey(
        AIProvider,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        default=None,
        related_name="failover_logs",
        help_text=(
            "The primary provider that failed, triggering failover to ``provider``. "
            "Null when no failover occurred."
        ),
    )

    class Meta:
        verbose_name = "AI usage log"
        verbose_name_plural = "AI usage logs"
        ordering = ("-created_at",)
        indexes = [
            models.Index(fields=["provider", "created_at"]),
            models.Index(fields=["category", "created_at"]),
            models.Index(fields=["success"]),
        ]

    def __str__(self) -> str:
        status = "ok" if self.success else "fail"
        return f"{self.provider_id} [{self.category}] {status} {self.latency_ms}ms"
