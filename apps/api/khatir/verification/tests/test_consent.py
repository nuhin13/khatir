"""Tests for verification consent capture — EPIC-17 T-003.

Covers ``record_verification_consent`` (writes a PDPA_NID_VERIFICATION
ConsentRecord) and ``has_valid_consent`` (refuses unless a non-revoked,
non-expired consent exists for the tenant).
"""

from __future__ import annotations

from datetime import timedelta

import pytest
from django.utils import timezone

from khatir.accounts.tests.factories import UserFactory
from khatir.compliance.enums import ConsentType
from khatir.compliance.models import ConsentRecord
from khatir.tenants.tests.factories import TenantFactory
from khatir.verification.consent import (
    has_valid_consent,
    record_verification_consent,
)
from khatir.verification.tests.factories import VerificationLogFactory

pytestmark = pytest.mark.django_db


def test_consent_recorded() -> None:
    tenant = TenantFactory()
    landlord = UserFactory()

    record = record_verification_consent(tenant, landlord)

    assert isinstance(record, ConsentRecord)
    assert record.pk is not None
    assert record.user_id == landlord.pk
    assert record.consent_type == ConsentType.PDPA_NID_VERIFICATION
    assert record.granted_at is not None
    assert record.revoked_at is None
    assert record.expires_at is None


def test_valid_consent_check() -> None:
    tenant = TenantFactory()
    landlord = UserFactory()
    record = record_verification_consent(tenant, landlord)

    # No verification log links the consent to the tenant yet.
    assert has_valid_consent(tenant) is False

    # Linking the consent to a verification log for this tenant makes it valid.
    VerificationLogFactory(tenant=tenant, consent_record=record)
    assert has_valid_consent(tenant) is True


def test_no_consent_is_invalid() -> None:
    tenant = TenantFactory()
    assert has_valid_consent(tenant) is False


def test_revoked_consent_is_invalid() -> None:
    tenant = TenantFactory()
    landlord = UserFactory()
    record = record_verification_consent(tenant, landlord)
    VerificationLogFactory(tenant=tenant, consent_record=record)
    assert has_valid_consent(tenant) is True

    record.revoked_at = timezone.now()
    record.save(update_fields=["revoked_at"])
    assert has_valid_consent(tenant) is False


def test_expired_consent_is_invalid() -> None:
    tenant = TenantFactory()
    landlord = UserFactory()
    record = record_verification_consent(tenant, landlord)
    record.expires_at = timezone.now() - timedelta(seconds=1)
    record.save(update_fields=["expires_at"])
    VerificationLogFactory(tenant=tenant, consent_record=record)

    assert has_valid_consent(tenant) is False


def test_future_expiry_consent_is_valid() -> None:
    tenant = TenantFactory()
    landlord = UserFactory()
    record = record_verification_consent(tenant, landlord)
    record.expires_at = timezone.now() + timedelta(days=30)
    record.save(update_fields=["expires_at"])
    VerificationLogFactory(tenant=tenant, consent_record=record)

    assert has_valid_consent(tenant) is True


def test_consent_scoped_to_tenant() -> None:
    """A consent linked to another tenant must not satisfy this tenant."""
    tenant_a = TenantFactory()
    tenant_b = TenantFactory()
    landlord = UserFactory()
    record = record_verification_consent(tenant_a, landlord)
    VerificationLogFactory(tenant=tenant_a, consent_record=record)

    assert has_valid_consent(tenant_a) is True
    assert has_valid_consent(tenant_b) is False
