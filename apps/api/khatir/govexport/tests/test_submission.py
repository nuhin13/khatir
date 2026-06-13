"""Tests for the pluggable gov-submission adapter (EPIC-26 T-003 §12).

Covers: the default produce-package-only stub (no real submission, status left
at ``generated``, audit row written), adapter resolution (explicit name, config
default, unknown name error), and that a custom adapter can be plugged in behind
the same contract without changing the caller.
"""

from __future__ import annotations

import datetime

import pytest

from khatir.accounts.enums import Role
from khatir.accounts.tests.factories import UserFactory
from khatir.compliance.enums import ConsentType
from khatir.compliance.models import ConsentRecord
from khatir.core.exceptions import ValidationError
from khatir.core.models import AuditEntry, SystemConfig
from khatir.govexport import builder, submission
from khatir.govexport.enums import GovExportStatus
from khatir.govexport.models import GovExport
from khatir.leases.enums import LeaseStatus
from khatir.leases.tests.factories import LeaseFactory
from khatir.tenants.tests.factories import TenantFactory

pytestmark = pytest.mark.django_db

PERIOD = "2026-05"


def _built_package(landlord) -> builder.BuiltPackage:
    """Build a real package with one consenting tenant for ``landlord``."""
    user = UserFactory(role=Role.TENANT)
    tenant = TenantFactory(linked_user=user)
    ConsentRecord.objects.create(user=user, consent_type=ConsentType.PDPA_DATA_SHARING)
    LeaseFactory(
        landlord=landlord,
        tenant=tenant,
        start_date=datetime.date(2026, 1, 1),
        end_date=datetime.date(2026, 12, 31),
        status=LeaseStatus.ACTIVE,
    )
    return builder.build_export_package(landlord=landlord, period=PERIOD, actor=landlord)


# ---------------------------------------------------------------------------
# Default stub: produce-package-only, no real submission
# ---------------------------------------------------------------------------


def test_default_adapter_is_produce_package_only() -> None:
    assert isinstance(submission.get_adapter(), submission.ProducePackageOnlyAdapter)


def test_stub_submit_does_not_mark_submitted() -> None:
    landlord = UserFactory(role=Role.LANDLORD)
    pkg = _built_package(landlord)
    result = submission.submit_package(pkg)
    assert result.submitted is False
    assert result.status == GovExportStatus.GENERATED
    assert result.reference == ""
    assert result.export_id == pkg.export.pk


def test_stub_submit_leaves_ledger_status_generated() -> None:
    landlord = UserFactory(role=Role.LANDLORD)
    pkg = _built_package(landlord)
    submission.submit_package(pkg)
    row = GovExport.objects.get(pk=pkg.export.pk)
    assert row.status == GovExportStatus.GENERATED


def test_stub_submit_writes_audit_without_raw_payload() -> None:
    landlord = UserFactory(role=Role.LANDLORD)
    pkg = _built_package(landlord)
    submission.submit_package(pkg)
    entry = AuditEntry.objects.get(
        action="govexport.submit", target_id=str(pkg.export.pk)
    )
    assert entry.after["submitted"] is False
    assert entry.after["file_ref"] == pkg.export.file_ref
    # No tenant PII payload in the audit snapshot.
    assert "records" not in entry.after
    assert "nid_number" not in entry.after


# ---------------------------------------------------------------------------
# Adapter resolution
# ---------------------------------------------------------------------------


def test_get_adapter_by_explicit_name() -> None:
    assert isinstance(submission.get_adapter("stub"), submission.ProducePackageOnlyAdapter)


def test_get_adapter_unknown_name_raises() -> None:
    with pytest.raises(ValidationError):
        submission.get_adapter("does-not-exist")


def test_get_adapter_reads_config(monkeypatch) -> None:
    SystemConfig.objects.update_or_create(
        key=submission.ADAPTER_CONFIG_KEY,
        defaults={"value": "stub"},
    )
    assert isinstance(submission.get_adapter(), submission.ProducePackageOnlyAdapter)


# ---------------------------------------------------------------------------
# Pluggability: a real adapter can replace the stub behind the same contract
# ---------------------------------------------------------------------------


def test_custom_adapter_is_pluggable(monkeypatch) -> None:
    class FakeGovAdapter(submission.GovSubmissionAdapter):
        name = "fake"

        def submit(self, package: builder.BuiltPackage) -> submission.SubmissionResult:
            return submission.SubmissionResult(
                export_id=package.export.pk,
                submitted=True,
                status=GovExportStatus.SUBMITTED,
                reference="RCPT-123",
                detail="accepted",
            )

    monkeypatch.setitem(submission._REGISTRY, "fake", FakeGovAdapter)
    landlord = UserFactory(role=Role.LANDLORD)
    pkg = _built_package(landlord)
    # Caller is unchanged — same submit_package entrypoint, different adapter.
    result = submission.submit_package(pkg, adapter_name="fake")
    assert result.submitted is True
    assert result.status == GovExportStatus.SUBMITTED
    assert result.reference == "RCPT-123"
