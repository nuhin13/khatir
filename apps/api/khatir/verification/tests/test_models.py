"""Tests for the verification domain — boolean-only logging + status transition.

Key invariant: ``VerificationLog`` must never carry raw EC data. We assert the
table's column set is restricted to the audit-safe fields, and that the tenant
status transitions correctly from a verification result.
"""

from __future__ import annotations

import pytest
from django.utils import timezone

from khatir.tenants.enums import VerificationStatus
from khatir.tenants.tests.factories import TenantFactory
from khatir.verification.enums import VerificationResult
from khatir.verification.models import VerificationLog
from khatir.verification.tests.factories import VerificationLogFactory

pytestmark = pytest.mark.django_db


# Raw EC payload fields that must NEVER be persisted on the log.
_FORBIDDEN_RAW_FIELDS = {
    "name",
    "dob",
    "address",
    "photo",
    "photo_ref",
    "nid",
    "nid_number",
    "nid_number_enc",
    "nid_number_masked",
    "ec_payload",
    "raw_response",
}


def test_log_create() -> None:
    log = VerificationLogFactory(result=VerificationResult.MATCHED)
    assert log.pk is not None
    assert log.result == VerificationResult.MATCHED
    assert log.tenant_id is not None
    assert log.requested_by_id is not None
    assert log.consent_record_id is not None
    assert log.provider_ref


def test_no_raw_data_columns() -> None:
    columns = {f.name for f in VerificationLog._meta.get_fields()}
    leaked = columns & _FORBIDDEN_RAW_FIELDS
    assert not leaked, f"VerificationLog must not store raw EC data: {leaked}"
    # Only the audit-safe surface is allowed.
    assert columns >= {
        "id",
        "tenant",
        "requested_by",
        "result",
        "provider_ref",
        "consent_record",
        "created_at",
        "updated_at",
    }


def test_status_transition_matched() -> None:
    tenant = TenantFactory(verification_status=VerificationStatus.UNVERIFIED)
    before = timezone.now()
    tenant.apply_verification_result(VerificationResult.MATCHED)
    tenant.refresh_from_db()
    assert tenant.verification_status == VerificationStatus.MATCHED
    assert tenant.verified_at is not None
    assert tenant.verified_at >= before


def test_status_transition_not_matched() -> None:
    tenant = TenantFactory(verification_status=VerificationStatus.UNVERIFIED)
    tenant.apply_verification_result(VerificationResult.NOT_MATCHED)
    tenant.refresh_from_db()
    assert tenant.verification_status == VerificationStatus.NOT_MATCHED
    assert tenant.verified_at is None


def test_status_transition_error() -> None:
    tenant = TenantFactory(verification_status=VerificationStatus.UNVERIFIED)
    tenant.apply_verification_result(VerificationResult.ERROR)
    tenant.refresh_from_db()
    assert tenant.verification_status == VerificationStatus.ERROR
    assert tenant.verified_at is None


def test_status_transition_rejects_unknown_result() -> None:
    tenant = TenantFactory()
    with pytest.raises(ValueError):
        tenant.apply_verification_result("bogus")


def test_log_is_append_only_instance() -> None:
    log = VerificationLogFactory()
    with pytest.raises(RuntimeError):
        log.delete()


def test_log_is_append_only_queryset() -> None:
    VerificationLogFactory()
    with pytest.raises(RuntimeError):
        VerificationLog.objects.all().delete()
