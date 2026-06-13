"""Tests for ``ConsentRecord`` and ``DataRequest`` models (T-001 §12)."""

from __future__ import annotations

import pytest
from django.db import models

from khatir.compliance.enums import ConsentType, DataRequestStatus, DataRequestType
from khatir.compliance.models import ConsentRecord, DataRequest

from .factories import ConsentRecordFactory, DataRequestFactory

pytestmark = pytest.mark.django_db


# --- ConsentRecord -----------------------------------------------------------


def test_consent_create() -> None:
    record: ConsentRecord = ConsentRecordFactory(  # type: ignore[assignment]
        consent_type=ConsentType.PDPA_DATA_COLLECTION
    )
    assert record.pk is not None
    assert record.user_id is not None
    assert record.consent_type == ConsentType.PDPA_DATA_COLLECTION
    assert record.granted_at is not None
    assert record.revoked_at is None
    assert record.expires_at is None
    assert str(record) != ""


def test_consent_record_optional_fields_default_none() -> None:
    record: ConsentRecord = ConsentRecordFactory()  # type: ignore[assignment]
    record.refresh_from_db()
    assert record.revoked_at is None
    assert record.expires_at is None


def test_consent_record_user_fk_on_delete_protect() -> None:
    """Deleting a user should be blocked while consent records exist (PROTECT)."""
    field = ConsentRecord._meta.get_field("user")
    assert isinstance(field, models.ForeignKey)
    assert field.remote_field.on_delete is models.PROTECT


def test_consent_record_is_not_soft_delete() -> None:
    """ConsentRecord is append-only — it does NOT use SoftDeleteModel."""
    assert not hasattr(ConsentRecord, "deleted_at")
    assert not hasattr(ConsentRecord, "is_deleted")


def test_consent_record_append_only_manager_blocks_delete() -> None:
    """The append-only manager must raise RuntimeError on delete()."""
    record: ConsentRecord = ConsentRecordFactory()  # type: ignore[assignment]
    with pytest.raises(RuntimeError, match="append-only"):
        record.delete()


def test_consent_record_qs_delete_blocked() -> None:
    """QuerySet bulk delete must also be blocked."""
    ConsentRecordFactory()
    with pytest.raises(RuntimeError, match="append-only"):
        ConsentRecord.objects.all().delete()


def test_consent_type_values_match_spec() -> None:
    """Wire values are lowercase snake_case as per enums.md."""
    for value in ConsentType.values:
        assert value == value.lower()
        assert " " not in value


def test_consent_record_indexes() -> None:
    index_fields = {tuple(idx.fields) for idx in ConsentRecord._meta.indexes}
    assert ("user",) in index_fields or ("user_id",) in index_fields or any(
        "user" in f for fields in index_fields for f in fields
    )


# --- DataRequest -------------------------------------------------------------


def test_data_request_create() -> None:
    req: DataRequest = DataRequestFactory(  # type: ignore[assignment]
        request_type=DataRequestType.EXPORT,
        status=DataRequestStatus.PENDING,
    )
    assert req.pk is not None
    assert req.user_id is not None
    assert req.request_type == DataRequestType.EXPORT
    assert req.status == DataRequestStatus.PENDING
    assert req.sla_due is not None
    assert req.completed_at is None
    assert req.handled_by_id is None
    assert str(req) != ""


def test_data_request_optional_fields_default_none() -> None:
    req: DataRequest = DataRequestFactory()  # type: ignore[assignment]
    req.refresh_from_db()
    assert req.completed_at is None
    assert req.handled_by_id is None


def test_data_request_user_fk_protect() -> None:
    field = DataRequest._meta.get_field("user")
    assert isinstance(field, models.ForeignKey)
    assert field.remote_field.on_delete is models.PROTECT


def test_data_request_handled_by_fk_set_null() -> None:
    """handled_by is nullable FK to AdminUser — SET_NULL on admin delete."""
    field = DataRequest._meta.get_field("handled_by")
    assert isinstance(field, models.ForeignKey)
    assert field.null is True
    assert field.remote_field.on_delete is models.SET_NULL


def test_data_request_type_values_match_spec() -> None:
    assert set(DataRequestType.values) == {"export", "delete"}


def test_data_request_status_values_match_spec() -> None:
    assert set(DataRequestStatus.values) == {"pending", "processing", "completed", "rejected"}


def test_data_request_status_index_present() -> None:
    index_fields = {tuple(idx.fields) for idx in DataRequest._meta.indexes}
    assert ("status",) in index_fields


def test_data_request_user_index_present() -> None:
    index_fields = {tuple(idx.fields) for idx in DataRequest._meta.indexes}
    assert ("user",) in index_fields or ("user_id",) in index_fields or any(
        "user" in f for fields in index_fields for f in fields
    )


def test_consent_record_timestamps_present() -> None:
    """ConsentRecord must have created_at and updated_at from TimeStampedModel."""
    record: ConsentRecord = ConsentRecordFactory()  # type: ignore[assignment]
    assert record.created_at is not None
    assert record.updated_at is not None


def test_data_request_timestamps_present() -> None:
    """DataRequest must have created_at and updated_at from TimeStampedModel."""
    req: DataRequest = DataRequestFactory()  # type: ignore[assignment]
    assert req.created_at is not None
    assert req.updated_at is not None
