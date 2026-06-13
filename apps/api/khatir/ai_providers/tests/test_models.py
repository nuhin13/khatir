"""Tests for ``AIProvider`` and ``AIUsageLog`` models (T-001 §12)."""

from __future__ import annotations

import pytest
from django.db import models

from khatir.ai_providers.enums import AICategory
from khatir.ai_providers.models import AIProvider, AIUsageLog
from khatir.core.encryption import decrypt, encrypt

from .factories import AIProviderFactory, AIUsageLogFactory

pytestmark = pytest.mark.django_db


# --- AICategory enum ---------------------------------------------------------


def test_ai_category_values_match_spec() -> None:
    """Wire values must match enums.md §AIProviderCategory."""
    assert set(AICategory.values) == {"chat", "voice", "ocr", "lease"}


# --- AIProvider --------------------------------------------------------------


def test_provider_create() -> None:
    provider: AIProvider = AIProviderFactory(  # type: ignore[assignment]
        category=AICategory.OCR,
        provider_key="google_vision",
        is_primary=True,
        model_name="vision-v1",
    )
    assert provider.pk is not None
    assert provider.category == AICategory.OCR
    assert provider.provider_key == "google_vision"
    assert provider.is_primary is True
    assert provider.model_name == "vision-v1"
    assert provider.active is True


def test_provider_str() -> None:
    provider: AIProvider = AIProviderFactory(  # type: ignore[assignment]
        provider_key="openai", is_primary=True
    )
    assert "openai" in str(provider)
    assert "primary" in str(provider)


def test_api_key_encrypted() -> None:
    """api_key_enc stores the encrypted form; decrypting it must yield the plaintext."""
    plaintext = "sk-super-secret-key"
    encrypted = encrypt(plaintext)
    provider: AIProvider = AIProviderFactory(api_key_enc=encrypted)  # type: ignore[assignment]
    provider.refresh_from_db()

    # The stored value must not equal the plaintext.
    assert provider.api_key_enc != plaintext
    # Decrypting must restore it.
    assert decrypt(provider.api_key_enc) == plaintext


def test_api_key_enc_not_in_list_display() -> None:
    """api_key_enc must never appear in admin list_display (privacy gate)."""
    from khatir.ai_providers.admin import AIProviderAdmin

    assert "api_key_enc" not in AIProviderAdmin.list_display


def test_api_key_enc_excluded_from_admin() -> None:
    """api_key_enc must be in admin exclude list so it never renders in forms."""
    from khatir.ai_providers.admin import AIProviderAdmin

    assert "api_key_enc" in AIProviderAdmin.exclude


def test_provider_defaults() -> None:
    provider: AIProvider = AIProviderFactory()  # type: ignore[assignment]
    provider.refresh_from_db()
    assert provider.is_primary is False
    assert provider.is_fallback is False
    assert provider.endpoint_url == ""
    assert provider.params_json is None
    assert provider.dpa_reference == ""
    assert provider.active is True


def test_provider_indexes() -> None:
    index_tuples = {tuple(idx.fields) for idx in AIProvider._meta.indexes}
    assert ("category", "is_primary") in index_tuples
    assert ("category", "active") in index_tuples


def test_provider_timestamps_set() -> None:
    provider: AIProvider = AIProviderFactory()  # type: ignore[assignment]
    assert provider.created_at is not None
    assert provider.updated_at is not None


# --- AIUsageLog --------------------------------------------------------------


def test_usage_log_create() -> None:
    log: AIUsageLog = AIUsageLogFactory(  # type: ignore[assignment]
        tokens_used=1500,
        cost_usd="0.05",
        success=True,
        latency_ms=320,
    )
    assert log.pk is not None
    assert log.tokens_used == 1500
    assert log.success is True
    assert log.latency_ms == 320
    assert log.failover_from_id is None


def test_usage_log_cost_is_decimal() -> None:
    """cost_usd must be a DecimalField(12,2) — never float."""
    field = AIUsageLog._meta.get_field("cost_usd")
    assert isinstance(field, models.DecimalField)
    assert field.max_digits == 12
    assert field.decimal_places == 2


def test_usage_log_failover_from() -> None:
    """failover_from records the primary provider when a fallback was used."""
    primary: AIProvider = AIProviderFactory(is_primary=True)  # type: ignore[assignment]
    fallback: AIProvider = AIProviderFactory(is_fallback=True)  # type: ignore[assignment]
    log: AIUsageLog = AIUsageLogFactory(  # type: ignore[assignment]
        provider=fallback,
        failover_from=primary,
    )
    log.refresh_from_db()
    assert log.failover_from_id == primary.pk
    assert log.provider_id == fallback.pk


def test_usage_log_failover_set_null_on_provider_delete() -> None:
    """Deleting the failover_from provider sets the FK to NULL (SET_NULL)."""
    primary: AIProvider = AIProviderFactory(is_primary=True)  # type: ignore[assignment]
    fallback: AIProvider = AIProviderFactory(is_fallback=True)  # type: ignore[assignment]
    log: AIUsageLog = AIUsageLogFactory(provider=fallback, failover_from=primary)  # type: ignore[assignment]
    primary_pk = primary.pk

    primary.delete()
    log.refresh_from_db()
    assert log.failover_from_id is None

    # Sanity: primary row is gone but the log and fallback still exist.
    assert not AIProvider.objects.filter(pk=primary_pk).exists()
    assert AIUsageLog.objects.filter(pk=log.pk).exists()


def test_usage_log_provider_fk_is_protect() -> None:
    field = AIUsageLog._meta.get_field("provider")
    assert isinstance(field, models.ForeignKey)
    assert field.remote_field.on_delete is models.PROTECT


def test_usage_log_failover_fk_is_set_null() -> None:
    field = AIUsageLog._meta.get_field("failover_from")
    assert isinstance(field, models.ForeignKey)
    assert field.null is True
    assert field.remote_field.on_delete is models.SET_NULL


def test_usage_log_indexes() -> None:
    index_tuples = {tuple(idx.fields) for idx in AIUsageLog._meta.indexes}
    assert ("provider", "created_at") in index_tuples
    assert ("category", "created_at") in index_tuples
    assert ("success",) in index_tuples


def test_usage_log_str() -> None:
    log: AIUsageLog = AIUsageLogFactory(success=True, latency_ms=150)  # type: ignore[assignment]
    assert "ok" in str(log)
    assert "150ms" in str(log)
