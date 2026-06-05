"""API tests for the lease-document endpoints (EPIC-18 · T-004 §12).

Exercises through DRF's ``APIClient`` with real authenticated landlords:

* ``POST /leases/{id}/generate-document`` — paid-tier gate (free → 402),
  ``ai_lease_enabled`` flag (off → 403), owner scope (foreign lease → 404),
  the disclaimer always present in the draft, and the audit write.
* ``PATCH /lease-documents/{id}`` — draft-only edit, required-clause guarantee
  (cannot blank the disclaimer), ``final`` locked (409), foreign → 404.
* ``POST /lease-documents/{id}/pdf`` — signed URL returned, disclaimer text in
  the rendered bytes, audit write, foreign → 404.

The AI gateway is mocked at ``call_gateway`` so generation never opens a socket.
"""

from __future__ import annotations

from typing import Any
from unittest import mock

import pytest
from rest_framework import status
from rest_framework.test import APIClient

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.ai_providers.client import AIGatewayResult
from khatir.billing.tests.factories import SubscriptionFactory
from khatir.core.models import AuditEntry
from khatir.featureflags.enums import FlagScope
from khatir.featureflags.models import FeatureFlag
from khatir.leasedocs.enums import LeaseDocumentStatus
from khatir.leasedocs.models import LeaseDocument
from khatir.leasedocs.scaffold import DEFAULT_DISCLAIMER_EN
from khatir.leases.tests.factories import LeaseFactory

from .factories import LeaseDocumentFactory

pytestmark = pytest.mark.django_db

_GATEWAY = "khatir.leasedocs.services.call_gateway"


@pytest.fixture
def landlord() -> User:
    created: User = UserFactory(  # type: ignore[assignment]
        phone="+8801712345678", name="Landlord", role=Role.LANDLORD
    )
    return created


@pytest.fixture
def paid_landlord(landlord: User) -> User:
    """A landlord with an active verification-bundled (paid) subscription."""
    SubscriptionFactory(user=landlord, tier__includes_verification=True)
    return landlord


@pytest.fixture
def client(landlord: User) -> APIClient:
    api = APIClient()
    api.force_authenticate(user=landlord)
    return api


def _gateway_result(clauses: dict[str, Any] | None = None) -> AIGatewayResult:
    return AIGatewayResult.from_response(
        {
            "data": {"clauses": clauses or {}},
            "model_name": "khatir-lease-v1",
            "provider_key": "openai",
        }
    )


# ── generate-document ────────────────────────────────────────────────────────


def test_generate_requires_paid_tier(client: APIClient, landlord: User) -> None:
    lease = LeaseFactory(landlord=landlord)
    with mock.patch(_GATEWAY) as gw:
        resp = client.post(f"/api/v1/leases/{lease.pk}/generate-document")
    assert resp.status_code == status.HTTP_402_PAYMENT_REQUIRED
    assert resp.json()["error"]["code"] == "feature_requires_upgrade"
    gw.assert_not_called()  # gated before any paid gateway call
    assert not LeaseDocument.objects.exists()


def test_generate_paid_creates_draft_with_disclaimer(
    client: APIClient, paid_landlord: User
) -> None:
    lease = LeaseFactory(landlord=paid_landlord)
    with mock.patch(_GATEWAY, return_value=_gateway_result()) as gw:
        resp = client.post(f"/api/v1/leases/{lease.pk}/generate-document")

    assert resp.status_code == status.HTTP_201_CREATED
    gw.assert_called_once()
    body = resp.json()
    assert body["status"] == LeaseDocumentStatus.DRAFT
    # Disclaimer is always present (scaffold fallback), per T-010.
    assert DEFAULT_DISCLAIMER_EN in body["content_json"]["disclaimer"]["body"]
    assert AuditEntry.objects.filter(action="leasedocument.generate").exists()


def test_generate_flag_off_returns_403(client: APIClient, paid_landlord: User) -> None:
    FeatureFlag.objects.create(
        key="ai_lease_enabled", scope=FlagScope.GLOBAL, enabled=False
    )
    lease = LeaseFactory(landlord=paid_landlord)
    with mock.patch(_GATEWAY) as gw:
        resp = client.post(f"/api/v1/leases/{lease.pk}/generate-document")
    assert resp.status_code == status.HTTP_403_FORBIDDEN
    assert resp.json()["error"]["code"] == "feature_disabled"
    gw.assert_not_called()


def test_generate_foreign_lease_is_404(client: APIClient, paid_landlord: User) -> None:
    other = LeaseFactory(landlord=UserFactory(role=Role.LANDLORD))
    with mock.patch(_GATEWAY, return_value=_gateway_result()):
        resp = client.post(f"/api/v1/leases/{other.pk}/generate-document")
    assert resp.status_code == status.HTTP_404_NOT_FOUND


# ── edit clauses ──────────────────────────────────────────────────────────────


def test_edit_draft_merges_clauses(client: APIClient, landlord: User) -> None:
    lease = LeaseFactory(landlord=landlord)
    doc = LeaseDocumentFactory(lease=lease, status=LeaseDocumentStatus.DRAFT)
    resp = client.patch(
        f"/api/v1/lease-documents/{doc.pk}",
        {"clauses": {"rent": "BDT 20,000 per month."}},
        format="json",
    )
    assert resp.status_code == status.HTTP_200_OK
    doc.refresh_from_db()
    assert doc.content_json["rent"]["body"] == "BDT 20,000 per month."
    # Other clauses untouched.
    assert "disclaimer" in doc.content_json
    assert AuditEntry.objects.filter(action="leasedocument.edit").exists()


def test_edit_cannot_blank_required_clause(client: APIClient, landlord: User) -> None:
    lease = LeaseFactory(landlord=landlord)
    doc = LeaseDocumentFactory(lease=lease, status=LeaseDocumentStatus.DRAFT)
    resp = client.patch(
        f"/api/v1/lease-documents/{doc.pk}",
        {"clauses": {"disclaimer": ""}},
        format="json",
    )
    assert resp.status_code == status.HTTP_400_BAD_REQUEST


def test_edit_final_is_locked(client: APIClient, landlord: User) -> None:
    lease = LeaseFactory(landlord=landlord)
    doc = LeaseDocumentFactory(lease=lease, status=LeaseDocumentStatus.FINAL)
    resp = client.patch(
        f"/api/v1/lease-documents/{doc.pk}",
        {"clauses": {"rent": "x"}},
        format="json",
    )
    assert resp.status_code == status.HTTP_409_CONFLICT


def test_edit_foreign_document_is_404(client: APIClient, landlord: User) -> None:
    other = LeaseDocumentFactory(lease=LeaseFactory(landlord=UserFactory(role=Role.LANDLORD)))
    resp = client.patch(
        f"/api/v1/lease-documents/{other.pk}",
        {"clauses": {"rent": "x"}},
        format="json",
    )
    assert resp.status_code == status.HTTP_404_NOT_FOUND


# ── render PDF ────────────────────────────────────────────────────────────────


def test_pdf_returns_signed_url_and_contains_disclaimer(
    client: APIClient, landlord: User, tmp_path: Any, settings: Any
) -> None:
    settings.ENCRYPTED_STORAGE_ROOT = str(tmp_path)
    settings.S3_BUCKET = ""
    lease = LeaseFactory(landlord=landlord)
    doc = LeaseDocumentFactory(lease=lease, status=LeaseDocumentStatus.FINAL)

    resp = client.post(f"/api/v1/lease-documents/{doc.pk}/pdf")
    assert resp.status_code == status.HTTP_200_OK
    body = resp.json()
    assert body["signed_url"]

    doc.refresh_from_db()
    assert doc.pdf_ref
    stored = (tmp_path / doc.pdf_ref).read_bytes()
    assert stored.startswith(b"%PDF")
    # The (English) disclaimer text is rendered into the PDF stream.
    assert b"not legal advice" in stored
    assert AuditEntry.objects.filter(action="leasedocument.pdf").exists()


def test_pdf_foreign_document_is_404(client: APIClient, landlord: User) -> None:
    other = LeaseDocumentFactory(lease=LeaseFactory(landlord=UserFactory(role=Role.LANDLORD)))
    resp = client.post(f"/api/v1/lease-documents/{other.pk}/pdf")
    assert resp.status_code == status.HTTP_404_NOT_FOUND
