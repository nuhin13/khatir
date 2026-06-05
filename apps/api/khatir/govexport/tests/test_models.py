"""Tests for the ``GovExport`` model (EPIC-26 T-001 §12)."""

from __future__ import annotations

import pytest
from django.db import models

from khatir.govexport.enums import GovExportStatus
from khatir.govexport.models import GovExport

from .factories import GovExportFactory

pytestmark = pytest.mark.django_db


# ---------------------------------------------------------------------------
# GovExport — create & basic fields
# ---------------------------------------------------------------------------


def test_export_create() -> None:
    """A GovExport can be created with all required fields."""
    export: GovExport = GovExportFactory()  # type: ignore[assignment]
    assert export.pk is not None
    assert export.landlord_id is not None
    assert export.period == "2026-05"
    assert export.format_version == "2024-v1"
    assert export.file_ref.startswith("govexport/")
    assert export.record_count == 3
    assert export.status == GovExportStatus.GENERATED
    assert str(export).startswith("GovExport #")


def test_export_default_ordering() -> None:
    """Exports are ordered newest-created-at first."""
    first: GovExport = GovExportFactory()  # type: ignore[assignment]
    second: GovExport = GovExportFactory()  # type: ignore[assignment]
    qs = list(GovExport.objects.all())
    assert qs[0].pk == second.pk
    assert qs[1].pk == first.pk


def test_export_timestamps() -> None:
    """created_at and updated_at are auto-set (from TimeStampedModel)."""
    export: GovExport = GovExportFactory()  # type: ignore[assignment]
    export.refresh_from_db()
    assert export.created_at is not None
    assert export.updated_at is not None


# ---------------------------------------------------------------------------
# Status enum
# ---------------------------------------------------------------------------


def test_status_default_is_generated() -> None:
    """A freshly created export defaults to 'generated'."""
    field = GovExport._meta.get_field("status")
    assert field.default == GovExportStatus.GENERATED


def test_status_choices() -> None:
    """status accepts only generated/submitted wire values."""
    assert GovExportStatus.GENERATED.value == "generated"
    assert GovExportStatus.SUBMITTED.value == "submitted"
    field = GovExport._meta.get_field("status")
    values = {choice[0] for choice in field.choices}
    assert values == {"generated", "submitted"}


def test_status_can_be_submitted() -> None:
    """An export can transition to the 'submitted' status."""
    export: GovExport = GovExportFactory(status=GovExportStatus.SUBMITTED)  # type: ignore[assignment]
    export.refresh_from_db()
    assert export.status == GovExportStatus.SUBMITTED


# ---------------------------------------------------------------------------
# FK constraints
# ---------------------------------------------------------------------------


def test_landlord_fk_is_protect() -> None:
    """landlord FK uses PROTECT — a landlord with exports cannot be deleted."""
    field = GovExport._meta.get_field("landlord")
    assert isinstance(field, models.ForeignKey)
    assert field.remote_field.on_delete is models.PROTECT


# ---------------------------------------------------------------------------
# Field types
# ---------------------------------------------------------------------------


def test_period_is_char_field() -> None:
    field = GovExport._meta.get_field("period")
    assert isinstance(field, models.CharField)
    assert field.max_length == 7


def test_format_version_is_char_field() -> None:
    field = GovExport._meta.get_field("format_version")
    assert isinstance(field, models.CharField)
    assert field.max_length == 40


def test_file_ref_is_char_field() -> None:
    field = GovExport._meta.get_field("file_ref")
    assert isinstance(field, models.CharField)
    assert field.max_length == 255


def test_record_count_is_positive_integer_field() -> None:
    field = GovExport._meta.get_field("record_count")
    assert isinstance(field, models.PositiveIntegerField)


# ---------------------------------------------------------------------------
# Privacy — §14 self-review: no raw payload stored beyond what's needed
# ---------------------------------------------------------------------------


def test_no_raw_payload_field_on_export() -> None:
    """GovExport must NOT store NID or any raw PII payload columns."""
    field_names = {f.name for f in GovExport._meta.get_fields()}
    assert "nid_number" not in field_names
    assert "payload" not in field_names
    assert "raw_data" not in field_names


# ---------------------------------------------------------------------------
# Indexes
# ---------------------------------------------------------------------------


def test_indexes_present() -> None:
    """landlord, period, status, and created_at must each have an index."""
    index_fields = {tuple(idx.fields) for idx in GovExport._meta.indexes}
    assert ("landlord",) in index_fields
    assert ("period",) in index_fields
    assert ("status",) in index_fields
    assert ("created_at",) in index_fields
