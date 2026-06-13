"""Tests for the gov-export package builder (EPIC-26 T-002 §12).

Covers: tenant selection by landlord + period (active leases only, dedup),
consent enforcement (only data-sharing-consented linked users), the
version-tagged structured file, deterministic zip output, encrypted storage,
the ``GovExport`` ledger row, and the audit entry.
"""

from __future__ import annotations

import datetime
import json
import zipfile

import pytest

from khatir.accounts.enums import Role
from khatir.accounts.tests.factories import UserFactory
from khatir.compliance.enums import ConsentType
from khatir.compliance.models import ConsentRecord
from khatir.core.models import AuditEntry
from khatir.govexport import builder
from khatir.govexport.enums import GovExportStatus
from khatir.govexport.models import GovExport
from khatir.leases.enums import LeaseStatus
from khatir.leases.tests.factories import LeaseFactory
from khatir.tenants.tests.factories import TenantFactory

pytestmark = pytest.mark.django_db

PERIOD = "2026-05"


def _consented_tenant(landlord, *, period_covered: bool = True, active: bool = True):
    """A tenant on a lease for ``landlord`` whose linked user has data-sharing consent."""
    user = UserFactory(role=Role.TENANT)
    tenant = TenantFactory(linked_user=user)
    ConsentRecord.objects.create(
        user=user,
        consent_type=ConsentType.PDPA_DATA_SHARING,
    )
    start = datetime.date(2026, 1, 1) if period_covered else datetime.date(2027, 1, 1)
    end = datetime.date(2026, 12, 31) if period_covered else datetime.date(2027, 12, 31)
    LeaseFactory(
        landlord=landlord,
        tenant=tenant,
        start_date=start,
        end_date=end,
        status=LeaseStatus.ACTIVE if active else LeaseStatus.DRAFT,
    )
    return tenant


# ---------------------------------------------------------------------------
# Tenant selection
# ---------------------------------------------------------------------------


def test_selects_active_lease_tenants_for_period() -> None:
    landlord = UserFactory(role=Role.LANDLORD)
    tenant = _consented_tenant(landlord)
    pkg = builder.build_export_package(landlord=landlord, period=PERIOD, actor=landlord)
    assert pkg.export.record_count == 1
    data = json.loads(_structured(pkg.zip_bytes))
    assert [r["tenant_id"] for r in data["records"]] == [tenant.pk]


def test_excludes_draft_leases() -> None:
    landlord = UserFactory(role=Role.LANDLORD)
    _consented_tenant(landlord, active=False)
    pkg = builder.build_export_package(landlord=landlord, period=PERIOD, actor=landlord)
    assert pkg.export.record_count == 0


def test_excludes_leases_outside_period() -> None:
    landlord = UserFactory(role=Role.LANDLORD)
    _consented_tenant(landlord, period_covered=False)
    pkg = builder.build_export_package(landlord=landlord, period=PERIOD, actor=landlord)
    assert pkg.export.record_count == 0


def test_excludes_other_landlords_tenants() -> None:
    landlord = UserFactory(role=Role.LANDLORD)
    other = UserFactory(role=Role.LANDLORD)
    _consented_tenant(other)
    pkg = builder.build_export_package(landlord=landlord, period=PERIOD, actor=landlord)
    assert pkg.export.record_count == 0


def test_dedups_tenant_with_multiple_leases() -> None:
    landlord = UserFactory(role=Role.LANDLORD)
    tenant = _consented_tenant(landlord)
    # A second active, period-covering lease for the same tenant.
    LeaseFactory(
        landlord=landlord,
        tenant=tenant,
        start_date=datetime.date(2026, 1, 1),
        end_date=datetime.date(2026, 12, 31),
        status=LeaseStatus.ACTIVE,
    )
    pkg = builder.build_export_package(landlord=landlord, period=PERIOD, actor=landlord)
    assert pkg.export.record_count == 1


# ---------------------------------------------------------------------------
# Consent enforcement
# ---------------------------------------------------------------------------


def test_excludes_tenant_without_linked_user() -> None:
    landlord = UserFactory(role=Role.LANDLORD)
    tenant = TenantFactory(linked_user=None)
    LeaseFactory(
        landlord=landlord,
        tenant=tenant,
        start_date=datetime.date(2026, 1, 1),
        end_date=datetime.date(2026, 12, 31),
        status=LeaseStatus.ACTIVE,
    )
    pkg = builder.build_export_package(landlord=landlord, period=PERIOD, actor=landlord)
    assert pkg.export.record_count == 0


def test_excludes_tenant_without_data_sharing_consent() -> None:
    landlord = UserFactory(role=Role.LANDLORD)
    user = UserFactory(role=Role.TENANT)
    tenant = TenantFactory(linked_user=user)
    # Different consent type — not data-sharing.
    ConsentRecord.objects.create(
        user=user, consent_type=ConsentType.PDPA_DATA_COLLECTION
    )
    LeaseFactory(
        landlord=landlord,
        tenant=tenant,
        start_date=datetime.date(2026, 1, 1),
        end_date=datetime.date(2026, 12, 31),
        status=LeaseStatus.ACTIVE,
    )
    pkg = builder.build_export_package(landlord=landlord, period=PERIOD, actor=landlord)
    assert pkg.export.record_count == 0


def test_excludes_revoked_consent() -> None:
    landlord = UserFactory(role=Role.LANDLORD)
    tenant = _consented_tenant(landlord)
    cr = ConsentRecord.objects.get(
        user=tenant.linked_user, consent_type=ConsentType.PDPA_DATA_SHARING
    )
    cr.revoked_at = datetime.datetime(2026, 4, 1, tzinfo=datetime.UTC)
    cr.save(update_fields=["revoked_at"])
    pkg = builder.build_export_package(landlord=landlord, period=PERIOD, actor=landlord)
    assert pkg.export.record_count == 0


def test_excludes_expired_consent() -> None:
    landlord = UserFactory(role=Role.LANDLORD)
    tenant = _consented_tenant(landlord)
    cr = ConsentRecord.objects.get(
        user=tenant.linked_user, consent_type=ConsentType.PDPA_DATA_SHARING
    )
    cr.expires_at = datetime.datetime(2020, 1, 1, tzinfo=datetime.UTC)
    cr.save(update_fields=["expires_at"])
    pkg = builder.build_export_package(landlord=landlord, period=PERIOD, actor=landlord)
    assert pkg.export.record_count == 0


# ---------------------------------------------------------------------------
# Structured file — versioned, no raw NID
# ---------------------------------------------------------------------------


def test_structured_file_is_version_tagged() -> None:
    landlord = UserFactory(role=Role.LANDLORD)
    _consented_tenant(landlord)
    pkg = builder.build_export_package(landlord=landlord, period=PERIOD, actor=landlord)
    data = json.loads(_structured(pkg.zip_bytes))
    assert data["format_version"] == builder.DEFAULT_FORMAT_VERSION
    assert data["period"] == PERIOD
    assert data["landlord_id"] == landlord.pk
    assert data["record_count"] == 1


def test_structured_file_has_no_plaintext_nid() -> None:
    landlord = UserFactory(role=Role.LANDLORD)
    _consented_tenant(landlord)
    pkg = builder.build_export_package(landlord=landlord, period=PERIOD, actor=landlord)
    data = json.loads(_structured(pkg.zip_bytes))
    record = data["records"][0]
    assert "nid_number" not in record
    assert "nid_masked" in record


# ---------------------------------------------------------------------------
# Package contents + determinism
# ---------------------------------------------------------------------------


def test_package_contains_structured_file_and_one_pdf_per_tenant() -> None:
    landlord = UserFactory(role=Role.LANDLORD)
    t1 = _consented_tenant(landlord)
    t2 = _consented_tenant(landlord)
    pkg = builder.build_export_package(landlord=landlord, period=PERIOD, actor=landlord)
    names = set(zipfile.ZipFile(_bio(pkg.zip_bytes)).namelist())
    assert builder.STRUCTURED_FILENAME in names
    assert f"dmp/tenant-{t1.pk}.pdf" in names
    assert f"dmp/tenant-{t2.pk}.pdf" in names
    assert pkg.export.record_count == 2


def test_zip_is_deterministic_for_same_inputs() -> None:
    structured = b'{"a": 1}'
    pdfs = [("dmp/tenant-1.pdf", b"%PDF-1.4 a"), ("dmp/tenant-2.pdf", b"%PDF-1.4 b")]
    assert builder.build_zip(structured, pdfs) == builder.build_zip(structured, pdfs)


# ---------------------------------------------------------------------------
# Ledger row + storage + audit
# ---------------------------------------------------------------------------


def test_creates_govexport_ledger_row() -> None:
    landlord = UserFactory(role=Role.LANDLORD)
    _consented_tenant(landlord)
    pkg = builder.build_export_package(landlord=landlord, period=PERIOD, actor=landlord)
    row = GovExport.objects.get(pk=pkg.export.pk)
    assert row.landlord_id == landlord.pk
    assert row.period == PERIOD
    assert row.format_version == builder.DEFAULT_FORMAT_VERSION
    assert row.status == GovExportStatus.GENERATED
    assert row.file_ref.startswith("gov_export/")
    assert row.record_count == 1


def test_writes_audit_entry_without_raw_payload() -> None:
    landlord = UserFactory(role=Role.LANDLORD)
    _consented_tenant(landlord)
    pkg = builder.build_export_package(landlord=landlord, period=PERIOD, actor=landlord)
    entry = AuditEntry.objects.get(
        action="govexport.generate", target_id=str(pkg.export.pk)
    )
    assert entry.actor_id == landlord.pk
    assert entry.after["record_count"] == 1
    assert entry.after["period"] == PERIOD
    # No tenant PII payload in the audit snapshot.
    assert "records" not in entry.after
    assert "nid_number" not in entry.after


def test_signed_url_for_export_round_trip() -> None:
    landlord = UserFactory(role=Role.LANDLORD)
    _consented_tenant(landlord)
    pkg = builder.build_export_package(landlord=landlord, period=PERIOD, actor=landlord)
    url = builder.signed_url_for_export(pkg.export)
    assert pkg.export.file_ref in url


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _bio(data: bytes):
    import io

    return io.BytesIO(data)


def _structured(zip_bytes: bytes) -> bytes:
    with zipfile.ZipFile(_bio(zip_bytes)) as zf:
        return zf.read(builder.STRUCTURED_FILENAME)
