"""Tests for the ``LeaseDocument`` model (EPIC-18 T-001 §12)."""

from __future__ import annotations

import pytest
from django.core.exceptions import ValidationError
from django.utils import timezone

from khatir.leasedocs.enums import LeaseDocumentStatus
from khatir.leasedocs.models import REQUIRED_CLAUSE_KEYS, LeaseDocument
from khatir.leases.tests.factories import LeaseFactory

from .factories import LeaseDocumentFactory

pytestmark = pytest.mark.django_db


# ---------------------------------------------------------------------------
# Basic shape
# ---------------------------------------------------------------------------


def test_create_lease_document() -> None:
    doc: LeaseDocument = LeaseDocumentFactory()  # type: ignore[assignment]
    assert doc.pk is not None
    assert doc.lease_id is not None
    assert doc.generated_by_id is not None
    assert doc.model_used == "khatir-lease-v1"


def test_default_status_is_draft() -> None:
    doc: LeaseDocument = LeaseDocumentFactory(status=LeaseDocumentStatus.DRAFT)  # type: ignore[assignment]
    doc.refresh_from_db()
    assert doc.status == LeaseDocumentStatus.DRAFT


def test_status_can_be_final() -> None:
    doc: LeaseDocument = LeaseDocumentFactory(status=LeaseDocumentStatus.FINAL)  # type: ignore[assignment]
    doc.refresh_from_db()
    assert doc.status == LeaseDocumentStatus.FINAL


def test_pdf_ref_and_generated_at_optional() -> None:
    lease = LeaseFactory()
    doc = LeaseDocument(lease=lease, content_json={})
    doc.save()
    doc.refresh_from_db()
    assert doc.pdf_ref == ""
    assert doc.generated_at is None


def test_generated_at_persists() -> None:
    now = timezone.now()
    doc: LeaseDocument = LeaseDocumentFactory(generated_at=now)  # type: ignore[assignment]
    doc.refresh_from_db()
    assert doc.generated_at is not None


def test_str() -> None:
    doc: LeaseDocument = LeaseDocumentFactory()  # type: ignore[assignment]
    assert f"lease {doc.lease_id}" in str(doc)


# ---------------------------------------------------------------------------
# Lease relationship & cascade
# ---------------------------------------------------------------------------


def test_cascade_delete_with_lease() -> None:
    doc: LeaseDocument = LeaseDocumentFactory()  # type: ignore[assignment]
    lease = doc.lease
    # Hard-delete the lease row to exercise the DB-level CASCADE.
    lease.hard_delete()
    assert not LeaseDocument.all_objects.filter(pk=doc.pk).exists()


def test_related_name_documents() -> None:
    doc: LeaseDocument = LeaseDocumentFactory()  # type: ignore[assignment]
    assert list(doc.lease.documents.all()) == [doc]


# ---------------------------------------------------------------------------
# Soft delete
# ---------------------------------------------------------------------------


def test_soft_delete_hides_from_default_manager() -> None:
    doc: LeaseDocument = LeaseDocumentFactory()  # type: ignore[assignment]
    doc.delete()
    assert not LeaseDocument.objects.filter(pk=doc.pk).exists()
    assert LeaseDocument.all_objects.filter(pk=doc.pk).exists()


# ---------------------------------------------------------------------------
# Required-clause guarantee
# ---------------------------------------------------------------------------


def test_full_clause_set_passes_validation() -> None:
    doc: LeaseDocument = LeaseDocumentFactory()  # type: ignore[assignment]
    doc.full_clean()  # must not raise


def test_empty_content_is_allowed() -> None:
    lease = LeaseFactory()
    doc = LeaseDocument(lease=lease, content_json={})
    doc.full_clean()  # empty draft is fine; guarantee only bites once filled


@pytest.mark.parametrize("missing_key", REQUIRED_CLAUSE_KEYS)
def test_missing_required_clause_fails_validation(missing_key: str) -> None:
    lease = LeaseFactory()
    clauses = {
        "parties": "x",
        "premises": "x",
        "rent": "x",
        "advance": "x",
        "term": "x",
        "disclaimer": "not legal advice",
    }
    del clauses[missing_key]
    doc = LeaseDocument(lease=lease, content_json=clauses)
    with pytest.raises(ValidationError):
        doc.full_clean()
    assert missing_key in doc.missing_required_clauses()


def test_disclaimer_is_required() -> None:
    lease = LeaseFactory()
    clauses = {
        "parties": "x",
        "premises": "x",
        "rent": "x",
        "advance": "x",
        "term": "x",
        # disclaimer deliberately omitted
    }
    doc = LeaseDocument(lease=lease, content_json=clauses)
    with pytest.raises(ValidationError):
        doc.full_clean()
    assert "disclaimer" in doc.missing_required_clauses()


def test_empty_string_clause_counts_as_missing() -> None:
    lease = LeaseFactory()
    clauses = dict.fromkeys(REQUIRED_CLAUSE_KEYS, "x")
    clauses["rent"] = ""
    doc = LeaseDocument(lease=lease, content_json=clauses)
    assert "rent" in doc.missing_required_clauses()
    with pytest.raises(ValidationError):
        doc.full_clean()


def test_missing_required_clauses_empty_when_complete() -> None:
    doc: LeaseDocument = LeaseDocumentFactory()  # type: ignore[assignment]
    assert doc.missing_required_clauses() == []


def test_non_dict_content_treated_as_all_missing() -> None:
    lease = LeaseFactory()
    doc = LeaseDocument(lease=lease, content_json=["not", "a", "dict"])
    assert set(doc.missing_required_clauses()) == set(REQUIRED_CLAUSE_KEYS)
    with pytest.raises(ValidationError):
        doc.full_clean()
