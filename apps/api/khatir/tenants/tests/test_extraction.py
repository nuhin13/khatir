"""Tests for the OCR/ASR extraction provider abstraction (T-004 §12).

Covers: normalization of OCR + ASR provider responses into ``ExtractedTenant``,
per-field confidence pass-through, config-driven provider selection with a
safe fallback, and the privacy invariant that no raw payload is held on the DTO.
The single backend seam (``_raw_extract``) is mocked so the public
``extract_from_*`` contract is exercised end-to-end.
"""

from __future__ import annotations

from datetime import date
from unittest import mock

import pytest

from khatir.ai_providers.client import AIGatewayResult
from khatir.tenants.extraction import (
    ExtractedTenant,
    TenantExtractionProvider,
    get_asr_provider,
    get_ocr_provider,
)
from khatir.tenants.extraction.asr_provider import DefaultAsrProvider
from khatir.tenants.extraction.dto import ExtractedField
from khatir.tenants.extraction.ocr_provider import (
    DefaultOcrProvider,
    GatewayOcrProvider,
)

# A loose, provider-shaped payload (extra key + messy values) to normalize.
_RAW_OCR = {
    "name": "  Karim Uddin ",
    "nid_number": "1234 5678 7788",
    "dob": "05-03-1990",
    "address": " Mirpur, Dhaka ",
    "confidence": {"name": 0.97, "nid_number": 0.88},
    "provider_internal_id": "should-be-ignored",
}
_RAW_ASR = {
    "name": "Rahima Begum",
    "nid_number": "9988776655",
    "dob": "1992-12-01",
    "address": "Uttara, Dhaka",
    "confidence": {"name": 0.7},
}


def test_ocr_extract_normalizes() -> None:
    provider = DefaultOcrProvider()
    with mock.patch.object(provider, "_raw_extract", return_value=_RAW_OCR):
        result = provider.extract_from_image(b"\x89PNG-fake-bytes")

    assert isinstance(result, ExtractedTenant)
    assert result.name.value == "Karim Uddin"  # stripped
    assert result.nid_number.value == "123456787788"  # digits only
    assert result.dob.value == date(1990, 3, 5)  # dd-mm-yyyy parsed
    assert result.address.value == "Mirpur, Dhaka"
    # per-field confidence flows through; absent ones are None
    assert result.name.confidence == pytest.approx(0.97)
    assert result.nid_number.confidence == pytest.approx(0.88)
    assert result.dob.confidence is None


def test_asr_extract_normalizes() -> None:
    provider = DefaultAsrProvider()
    with mock.patch.object(provider, "_raw_extract", return_value=_RAW_ASR):
        result = provider.extract_from_audio(b"fake-ogg-bytes")

    assert result.name.value == "Rahima Begum"
    assert result.nid_number.value == "9988776655"
    assert result.dob.value == date(1992, 12, 1)  # iso parsed
    assert result.address.value == "Uttara, Dhaka"
    assert result.name.confidence == pytest.approx(0.7)


def test_empty_payload_yields_empty_dto() -> None:
    provider = DefaultOcrProvider()
    with mock.patch.object(provider, "_raw_extract", return_value={}):
        result = provider.extract_from_image(b"unreadable")
    assert result.is_empty() is True
    assert result.nid_number.value is None


def test_no_raw_payload_on_dto() -> None:
    """Privacy: only the four normalized fields exist on the DTO — never a
    pocket holding the raw provider response."""
    provider = DefaultOcrProvider()
    with mock.patch.object(provider, "_raw_extract", return_value=_RAW_OCR):
        result = provider.extract_from_image(b"x")
    field_names = {f.name for f in result.__dataclass_fields__.values()}
    assert field_names == {"name", "nid_number", "dob", "address"}
    for f in field_names:
        assert isinstance(getattr(result, f), ExtractedField)


@pytest.mark.django_db
def test_provider_selection_default() -> None:
    """With no config key set, the registry returns the built-in providers."""
    assert isinstance(get_ocr_provider(), DefaultOcrProvider)
    assert isinstance(get_asr_provider(), DefaultAsrProvider)
    assert isinstance(get_ocr_provider(), TenantExtractionProvider)


@pytest.mark.django_db
def test_provider_selection_unknown_key_falls_back() -> None:
    """An unknown configured key falls back to the default provider rather
    than raising, so callers always get a working instance."""
    with mock.patch(
        "khatir.tenants.extraction.ocr_provider.get_config",
        return_value="nonexistent_provider",
    ):
        assert isinstance(get_ocr_provider(), DefaultOcrProvider)


@pytest.mark.django_db
def test_provider_selection_reads_config_key() -> None:
    """The OCR registry consults the ``ocr_provider_key`` config; a known key
    resolves to its registered provider class."""
    with mock.patch.dict(
        "khatir.tenants.extraction.ocr_provider._OCR_PROVIDERS",
        {"custom": DefaultOcrProvider},
        clear=False,
    ), mock.patch(
        "khatir.tenants.extraction.ocr_provider.get_config",
        return_value="custom",
    ) as cfg:
        provider = get_ocr_provider()
    cfg.assert_called_once_with("ocr_provider_key", "default")
    assert isinstance(provider, DefaultOcrProvider)


def test_wrong_modality_raises() -> None:
    with pytest.raises(NotImplementedError):
        DefaultOcrProvider().extract_from_audio(b"x")
    with pytest.raises(NotImplementedError):
        DefaultAsrProvider().extract_from_image(b"x")


# --- gateway-backed OCR provider (EPIC-14.T-008) -----------------------------

# The gateway returns each field as a {value, confidence} envelope; dob arrives
# as an ISO string. extra/odd keys degrade gracefully to None.
_GATEWAY_OCR_DATA = {
    "name": {"value": "  Karim Uddin ", "confidence": 0.97},
    "nid_number": {"value": "1234 5678 7788", "confidence": 0.88},
    "dob": {"value": "1990-03-05", "confidence": None},
    "address": {"value": " Mirpur, Dhaka ", "confidence": 0.5},
}


def test_gateway_ocr_provider_normalizes_envelope() -> None:
    """The gateway provider forwards the image via ``extract_nid`` and maps the
    gateway's per-field envelope onto the normalized DTO."""
    result = AIGatewayResult(data=_GATEWAY_OCR_DATA, provider_key="google_vision")
    with mock.patch(
        "khatir.tenants.extraction.ocr_provider.aiproxy_client.extract_nid",
        return_value=result,
    ) as extract:
        out = GatewayOcrProvider().extract_from_image(b"\x89PNG-fake-bytes")

    extract.assert_called_once_with(b"\x89PNG-fake-bytes")
    assert isinstance(out, ExtractedTenant)
    assert out.name.value == "Karim Uddin"  # stripped
    assert out.nid_number.value == "123456787788"  # digits only
    assert out.dob.value == date(1990, 3, 5)  # iso string parsed to date
    assert out.address.value == "Mirpur, Dhaka"
    assert out.name.confidence == pytest.approx(0.97)
    assert out.nid_number.confidence == pytest.approx(0.88)
    assert out.dob.confidence is None


def test_gateway_ocr_provider_empty_data_yields_empty_dto() -> None:
    result = AIGatewayResult(data={})
    with mock.patch(
        "khatir.tenants.extraction.ocr_provider.aiproxy_client.extract_nid",
        return_value=result,
    ):
        out = GatewayOcrProvider().extract_from_image(b"unreadable")
    assert out.is_empty() is True


def test_gateway_ocr_provider_tolerates_odd_field_shape() -> None:
    """A missing/non-dict field envelope degrades to ``None`` rather than raising."""
    result = AIGatewayResult(data={"name": "not-an-envelope", "nid_number": None})
    with mock.patch(
        "khatir.tenants.extraction.ocr_provider.aiproxy_client.extract_nid",
        return_value=result,
    ):
        out = GatewayOcrProvider().extract_from_image(b"x")
    assert out.name.value is None
    assert out.nid_number.value is None


def test_gateway_ocr_provider_rejects_audio() -> None:
    with pytest.raises(NotImplementedError):
        GatewayOcrProvider().extract_from_audio(b"x")


@pytest.mark.django_db
def test_gateway_provider_selected_by_config() -> None:
    """Setting ``ocr_provider_key=gateway`` routes OCR through the gateway impl."""
    with mock.patch(
        "khatir.tenants.extraction.ocr_provider.get_config",
        return_value="gateway",
    ):
        assert isinstance(get_ocr_provider(), GatewayOcrProvider)
