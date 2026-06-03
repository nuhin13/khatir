"""Tests for the ``DMPFormRecord`` model (EPIC-05 T-001 §12)."""

from __future__ import annotations

import datetime

import pytest
from django.db import models

from khatir.dmpforms.models import DMPFormRecord

from .factories import DMPFormRecordFactory

pytestmark = pytest.mark.django_db


# ---------------------------------------------------------------------------
# DMPFormRecord — create & basic fields
# ---------------------------------------------------------------------------


def test_record_create() -> None:
    """A DMPFormRecord can be created with all required fields."""
    record: DMPFormRecord = DMPFormRecordFactory()  # type: ignore[assignment]
    assert record.pk is not None
    assert record.tenant_id is not None
    assert record.template_version == "2024-v1"
    assert record.pdf_ref.startswith("dmpforms/")
    assert record.generated_by_id is not None
    assert record.generated_at is not None
    assert str(record).startswith("DMPFormRecord #")


def test_record_default_ordering() -> None:
    """Records are ordered newest-generated-at first."""
    early: DMPFormRecord = DMPFormRecordFactory(  # type: ignore[assignment]
        generated_at=datetime.datetime(2026, 1, 1, tzinfo=datetime.UTC)
    )
    late: DMPFormRecord = DMPFormRecordFactory(  # type: ignore[assignment]
        generated_at=datetime.datetime(2026, 6, 1, tzinfo=datetime.UTC)
    )
    qs = list(DMPFormRecord.objects.all())
    assert qs[0].pk == late.pk
    assert qs[1].pk == early.pk


def test_record_timestamps() -> None:
    """created_at and updated_at are auto-set (from TimeStampedModel)."""
    record: DMPFormRecord = DMPFormRecordFactory()  # type: ignore[assignment]
    record.refresh_from_db()
    assert record.created_at is not None
    assert record.updated_at is not None


# ---------------------------------------------------------------------------
# FK constraints
# ---------------------------------------------------------------------------


def test_tenant_fk_is_protect() -> None:
    """tenant FK uses PROTECT — a tenant with DMP form records cannot be deleted."""
    field = DMPFormRecord._meta.get_field("tenant")
    assert isinstance(field, models.ForeignKey)
    assert field.remote_field.on_delete is models.PROTECT


def test_generated_by_fk_is_set_null() -> None:
    """generated_by FK uses SET_NULL — deleting a user does not destroy audit rows."""
    field = DMPFormRecord._meta.get_field("generated_by")
    assert isinstance(field, models.ForeignKey)
    assert field.null is True
    assert field.remote_field.on_delete is models.SET_NULL


def test_generated_by_nullable() -> None:
    """generated_by is nullable (system-generated records have no user)."""
    record: DMPFormRecord = DMPFormRecordFactory(generated_by=None)  # type: ignore[assignment]
    record.refresh_from_db()
    assert record.generated_by_id is None


# ---------------------------------------------------------------------------
# Field types
# ---------------------------------------------------------------------------


def test_template_version_is_char_field() -> None:
    field = DMPFormRecord._meta.get_field("template_version")
    assert isinstance(field, models.CharField)
    assert field.max_length == 40


def test_pdf_ref_is_char_field() -> None:
    field = DMPFormRecord._meta.get_field("pdf_ref")
    assert isinstance(field, models.CharField)
    assert field.max_length == 255


def test_generated_at_is_datetime_field() -> None:
    field = DMPFormRecord._meta.get_field("generated_at")
    assert isinstance(field, models.DateTimeField)


# ---------------------------------------------------------------------------
# Privacy — §14 self-review: no raw payload stored beyond what's needed
# ---------------------------------------------------------------------------


def test_no_nid_field_on_record() -> None:
    """DMPFormRecord must NOT store NID or any raw PII payload columns."""
    field_names = {f.name for f in DMPFormRecord._meta.get_fields()}
    assert "nid_number" not in field_names
    assert "nid_number_enc" not in field_names
    assert "nid_number_masked" not in field_names


# ---------------------------------------------------------------------------
# Indexes
# ---------------------------------------------------------------------------


def test_indexes_present() -> None:
    """tenant, generated_by, and generated_at must each have an index."""
    index_fields = {tuple(idx.fields) for idx in DMPFormRecord._meta.indexes}
    assert ("tenant",) in index_fields
    assert ("generated_by",) in index_fields
    assert ("generated_at",) in index_fields
