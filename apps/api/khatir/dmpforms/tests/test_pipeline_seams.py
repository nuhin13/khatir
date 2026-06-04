"""Seam tests for the assembler, renderer, and storage helper (EPIC-05 T-005).

These exercise the *real* (un-mocked) seams the generate pipeline orchestrates,
so the orchestration in ``services.py`` is proven against working building
blocks as well as against mocks. The production assembler (T-002), renderer
(T-003), and S3 storage (EPIC-04 T-003) flesh these out further.
"""

from __future__ import annotations

import pytest

from khatir.accounts.tests.factories import UserFactory
from khatir.core import storage
from khatir.core.encryption import encrypt
from khatir.dmpforms.assembler import assemble_dmp_data
from khatir.dmpforms.pdf import render_dmp_pdf
from khatir.dmpforms.services import generate_dmp_pdf
from khatir.leases.tests.factories import LeaseFactory
from khatir.properties.tests.factories import BuildingFactory, UnitFactory
from khatir.tenants.tests.factories import (
    TenantFactory,
    TenantFamilyMemberFactory,
)

pytestmark = pytest.mark.django_db


def _full_tenant():  # type: ignore[no-untyped-def]
    tenant = TenantFactory(  # type: ignore[misc]
        name="Karim Uddin",
        nid_number_masked="****7788",
        nid_number_enc=encrypt("1234567788").encode("utf-8"),
    )
    TenantFamilyMemberFactory(tenant=tenant, name="Rahima", relation="spouse")
    landlord = UserFactory(name="Owner Mia")
    building = BuildingFactory(name="Karim Manzil", owner=landlord)
    unit = UnitFactory(building=building)
    LeaseFactory(tenant=tenant, unit=unit, landlord=landlord)
    return tenant


def test_assemble_all_fields() -> None:
    tenant = _full_tenant()
    data = assemble_dmp_data(tenant, actor=None)

    assert data.tenant_name == "Karim Uddin"
    # Full NID comes back via the audited decrypt path (server-side only).
    assert data.nid_number == "1234567788"
    assert data.building_address
    assert data.landlord_name == "Owner Mia"
    assert len(data.family_members) == 1
    assert data.family_members[0].relation == "spouse"


def test_render_produces_pdf_bytes() -> None:
    tenant = _full_tenant()
    data = assemble_dmp_data(tenant, actor=None)
    pdf = render_dmp_pdf(data, "2026.1")

    assert pdf.startswith(b"%PDF")
    assert pdf.rstrip().endswith(b"%%EOF")


def test_render_is_deterministic() -> None:
    tenant = _full_tenant()
    data = assemble_dmp_data(tenant, actor=None)
    assert render_dmp_pdf(data, "2026.1") == render_dmp_pdf(data, "2026.1")


def test_store_and_signed_url(tmp_path, settings) -> None:  # type: ignore[no-untyped-def]
    settings.ENCRYPTED_STORAGE_ROOT = str(tmp_path)
    key = storage.store_encrypted(b"%PDF-1.4 hello", kind="pdf")

    assert key.startswith("pdf/")
    assert (tmp_path / key).read_bytes() == b"%PDF-1.4 hello"
    url = storage.signed_url(key, ttl=60)
    assert key in url and "sig=" in url


def test_generate_end_to_end_no_mocks(tmp_path, settings) -> None:  # type: ignore[no-untyped-def]
    settings.ENCRYPTED_STORAGE_ROOT = str(tmp_path)
    tenant = _full_tenant()

    result = generate_dmp_pdf(tenant=tenant, actor=None)

    assert result.record.pk is not None
    assert result.record.pdf_ref.startswith("pdf/")
    assert (tmp_path / result.record.pdf_ref).read_bytes().startswith(b"%PDF")
    assert result.signed_url
