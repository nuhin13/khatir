"""Tests for the ``Tenant`` and ``TenantFamilyMember`` models (T-001 §12)."""

from __future__ import annotations

import pytest
from django.db import models

from khatir.tenants.enums import VerificationStatus
from khatir.tenants.models import Tenant, TenantFamilyMember

from .factories import TenantFactory, TenantFamilyMemberFactory

pytestmark = pytest.mark.django_db


# --- Tenant -----------------------------------------------------------------


def test_tenant_create() -> None:
    tenant: Tenant = TenantFactory(name="Karim Uddin")  # type: ignore[assignment]
    assert tenant.pk is not None
    assert tenant.name == "Karim Uddin"
    assert tenant.verification_status == VerificationStatus.UNVERIFIED
    assert tenant.is_app_user is False
    assert tenant.linked_user_id is None
    assert str(tenant) == "Karim Uddin"


def test_tenant_optional_fields_default_empty() -> None:
    tenant: Tenant = TenantFactory()  # type: ignore[assignment]
    tenant.refresh_from_db()
    assert tenant.dob is None
    assert tenant.verified_at is None
    assert tenant.address == ""
    assert tenant.photo_ref == ""


def test_tenant_soft_delete() -> None:
    tenant: Tenant = TenantFactory()  # type: ignore[assignment]
    pk = tenant.pk
    tenant.delete()
    assert tenant.is_deleted is True
    assert Tenant.objects.filter(pk=pk).count() == 0
    assert Tenant.all_objects.filter(pk=pk).count() == 1


def test_linked_user_is_set_null() -> None:
    field = Tenant._meta.get_field("linked_user")
    assert isinstance(field, models.ForeignKey)
    assert field.null is True
    assert field.remote_field.on_delete is models.SET_NULL


# --- NID privacy (self-review §14) ------------------------------------------


def test_masked_field_present() -> None:
    tenant: Tenant = TenantFactory(nid_number_masked="****7788")  # type: ignore[assignment]
    tenant.refresh_from_db()
    assert tenant.nid_number_masked == "****7788"


def test_no_plaintext_nid_column() -> None:
    """Only an encrypted (bytea) column and a masked column may exist — never
    a plaintext ``nid_number``."""
    field_names = {f.name for f in Tenant._meta.get_fields()}
    assert "nid_number" not in field_names
    assert "nid_number_enc" in field_names
    assert "nid_number_masked" in field_names


def test_nid_enc_is_binary() -> None:
    field = Tenant._meta.get_field("nid_number_enc")
    assert isinstance(field, models.BinaryField)


# --- VerificationStatus matches enums.md ------------------------------------


def test_verification_status_values_match_spec() -> None:
    assert set(VerificationStatus.values) == {
        "unverified",
        "matched",
        "not_matched",
        "error",
    }


# --- TenantFamilyMember -----------------------------------------------------


def test_family_member_create() -> None:
    member: TenantFamilyMember = TenantFamilyMemberFactory(  # type: ignore[assignment]
        name="Rahima", relation="spouse"
    )
    assert member.pk is not None
    assert member.tenant_id is not None
    assert member.relation == "spouse"
    assert str(member) == "Rahima (spouse)"


def test_family_members_cascade_on_tenant_delete() -> None:
    """Hard-deleting a tenant removes their family members (CASCADE)."""
    member: TenantFamilyMember = TenantFamilyMemberFactory()  # type: ignore[assignment]
    tenant = member.tenant
    member_pk = member.pk
    tenant.hard_delete()
    assert TenantFamilyMember.objects.filter(pk=member_pk).count() == 0


def test_family_fk_is_cascade() -> None:
    field = TenantFamilyMember._meta.get_field("tenant")
    assert isinstance(field, models.ForeignKey)
    assert field.remote_field.on_delete is models.CASCADE


# --- Indexes ----------------------------------------------------------------


def test_masked_index_present() -> None:
    index_fields = {tuple(idx.fields) for idx in Tenant._meta.indexes}
    assert ("nid_number_masked",) in index_fields
