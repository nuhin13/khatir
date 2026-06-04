"""Tests for NID encryption + masking on the ``Tenant`` model (T-002 §12).

Verifies that ``set_nid`` encrypts and masks, that ``get_nid`` is the only
plaintext path, and that no plaintext NID is persisted in any column. There is
no serializer yet (built in T-007); the "hidden by default" guarantee is
asserted at the model layer — the masked form never equals the raw NID and the
ciphertext column is opaque.
"""

from __future__ import annotations

import pytest

from khatir.core.encryption import decrypt
from khatir.tenants.models import Tenant

from .factories import TenantFactory

pytestmark = pytest.mark.django_db

RAW_NID = "1990123456789"


def test_set_nid_encrypts_and_masks() -> None:
    tenant: Tenant = TenantFactory()  # type: ignore[assignment]
    tenant.set_nid(RAW_NID)
    tenant.save()

    assert tenant.nid_number_enc is not None
    # Ciphertext bytes must not contain the plaintext.
    assert RAW_NID.encode("utf-8") not in bytes(tenant.nid_number_enc)
    # Masked form keeps only the last four.
    assert tenant.nid_number_masked == "*********6789"
    assert RAW_NID not in tenant.nid_number_masked


def test_set_get_nid_roundtrip() -> None:
    tenant: Tenant = TenantFactory()  # type: ignore[assignment]
    tenant.set_nid(RAW_NID)
    tenant.save()
    tenant.refresh_from_db()

    assert tenant.get_nid() == RAW_NID


def test_get_nid_none_when_unset() -> None:
    tenant: Tenant = TenantFactory()  # type: ignore[assignment]
    assert tenant.get_nid() is None


def test_masked_format_last_four() -> None:
    tenant: Tenant = TenantFactory()  # type: ignore[assignment]
    tenant.set_nid("12345678")
    assert tenant.nid_number_masked == "****5678"
    assert tenant.nid_number_masked.startswith("****")
    assert tenant.nid_number_masked.endswith("5678")


def test_set_nid_empty_clears_both_fields() -> None:
    tenant: Tenant = TenantFactory()  # type: ignore[assignment]
    tenant.set_nid(RAW_NID)
    tenant.save()
    tenant.set_nid("")
    tenant.save()
    tenant.refresh_from_db()

    assert tenant.nid_number_enc in (None, b"")
    assert tenant.nid_number_masked == ""
    assert tenant.get_nid() is None


def test_ciphertext_is_decryptable_only_explicitly() -> None:
    """The stored column is opaque ciphertext; only ``decrypt`` recovers it."""
    tenant: Tenant = TenantFactory()  # type: ignore[assignment]
    tenant.set_nid(RAW_NID)
    tenant.save()
    tenant.refresh_from_db()

    assert tenant.nid_number_enc is not None
    token = bytes(tenant.nid_number_enc).decode("utf-8")
    assert token != RAW_NID
    assert decrypt(token) == RAW_NID


def test_no_default_attribute_exposes_full_nid() -> None:
    """No field on the model holds the plaintext NID after a set."""
    tenant: Tenant = TenantFactory()  # type: ignore[assignment]
    tenant.set_nid(RAW_NID)
    tenant.save()
    tenant.refresh_from_db()

    for field in tenant._meta.get_fields():
        if not hasattr(field, "attname"):
            continue
        value = getattr(tenant, field.attname, None)
        if isinstance(value, str):
            assert value != RAW_NID
        if isinstance(value, (bytes, bytearray, memoryview)):
            assert RAW_NID.encode("utf-8") not in bytes(value)
