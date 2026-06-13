"""API + service tests for the DMP PDF generate pipeline (EPIC-05 T-005 §12).

Exercises ``POST /api/v1/tenants/{id}/dmpform/pdf`` and ``GET
/api/v1/dmpforms/{id}`` through DRF's ``APIClient``. Render and storage are
**mocked** (T-005 §3) so the tests assert orchestration, not template fidelity
or real S3. Covers: signed URL returned, record created with template_version,
free-tier allowed, owner scoping (cross-user 404), and the generate audit row.
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
from khatir.core.models import AuditEntry
from khatir.dmpforms.models import DMPFormRecord
from khatir.leases.tests.factories import LeaseFactory
from khatir.properties.tests.factories import BuildingFactory, UnitFactory
from khatir.tenants.models import Tenant
from khatir.tenants.tests.factories import TenantFactory

from .factories import DMPFormRecordFactory

pytestmark = pytest.mark.django_db

SERVICE = "khatir.dmpforms.services"


@pytest.fixture
def landlord() -> User:
    created: User = UserFactory(  # type: ignore[assignment]
        phone="+8801712340001", name="Owner", role=Role.LANDLORD
    )
    return created


@pytest.fixture
def client(landlord: User) -> APIClient:
    api = APIClient()
    api.force_authenticate(user=landlord)
    return api


def _owned_tenant(landlord: User) -> Tenant:
    """A tenant the landlord owns through a lease (visible via for_user)."""
    tenant: Tenant = TenantFactory(name="Karim")  # type: ignore[assignment]
    building = BuildingFactory(owner=landlord)
    unit = UnitFactory(building=building)
    LeaseFactory(tenant=tenant, unit=unit, landlord=landlord)
    return tenant


def _generate_url(tenant_id: object) -> str:
    return f"/api/v1/tenants/{tenant_id}/dmpform/pdf"


def _record_url(record_id: object) -> str:
    return f"/api/v1/dmpforms/{record_id}"


# ── mocking helpers ───────────────────────────────────────────────────────────


def _mock_pipeline() -> tuple[Any, Any]:
    """Patch the render + storage seams the service orchestrates."""
    render = mock.patch(f"{SERVICE}.render_dmp_pdf", return_value=b"%PDF-1.4 fake")
    store = mock.patch.object(
        __import__("khatir.core.storage", fromlist=["store_encrypted"]),
        "store_encrypted",
        return_value="pdf/opaque-key",
    )
    return render, store


# ── generate ───────────────────────────────────────────────────────────────


def test_generate_pdf_returns_signed_url(client: APIClient, landlord: User) -> None:
    tenant = _owned_tenant(landlord)
    render, store = _mock_pipeline()
    with render, store, mock.patch(
        "khatir.core.storage.signed_url", return_value="https://storage.local/pdf/x?sig=abc"
    ):
        resp = client.post(_generate_url(tenant.pk), {}, format="json")

    assert resp.status_code == status.HTTP_201_CREATED
    assert resp.data["signed_url"] == "https://storage.local/pdf/x?sig=abc"
    assert resp.data["record"]["pdf_ref"] == "pdf/opaque-key"


def test_record_created(client: APIClient, landlord: User) -> None:
    tenant = _owned_tenant(landlord)
    render, store = _mock_pipeline()
    with render, store, mock.patch("khatir.core.storage.signed_url", return_value="https://x/y"):
        resp = client.post(_generate_url(tenant.pk), {}, format="json")

    assert resp.status_code == status.HTTP_201_CREATED
    record = DMPFormRecord.objects.get(pk=resp.data["record"]["id"])
    assert record.tenant_id == tenant.pk
    assert record.generated_by_id == landlord.pk
    assert record.pdf_ref == "pdf/opaque-key"
    # Record carries the template_version used (T-005 §14 self-review).
    assert record.template_version
    assert resp.data["record"]["template_version"] == record.template_version


def test_render_receives_template_version(client: APIClient, landlord: User) -> None:
    tenant = _owned_tenant(landlord)
    store = mock.patch.object(
        __import__("khatir.core.storage", fromlist=["store_encrypted"]),
        "store_encrypted",
        return_value="pdf/opaque-key",
    )
    render = mock.patch(f"{SERVICE}.render_dmp_pdf", return_value=b"%PDF")
    with render as render_mock, store, mock.patch(
        "khatir.core.storage.signed_url", return_value="https://x/y"
    ):
        resp = client.post(_generate_url(tenant.pk), {}, format="json")

    assert resp.status_code == status.HTTP_201_CREATED
    # render(dmp_data, template_version) — second positional arg is the version.
    _, called_version = render_mock.call_args.args
    assert called_version == resp.data["record"]["template_version"]


def test_free_tier_allowed(client: APIClient, landlord: User) -> None:
    """No plan gate — a brand-new free-tier owner may generate immediately."""
    tenant = _owned_tenant(landlord)
    render, store = _mock_pipeline()
    with render, store, mock.patch("khatir.core.storage.signed_url", return_value="https://x/y"):
        resp = client.post(_generate_url(tenant.pk), {}, format="json")

    assert resp.status_code == status.HTTP_201_CREATED


def test_generate_writes_audit(client: APIClient, landlord: User) -> None:
    tenant = _owned_tenant(landlord)
    render, store = _mock_pipeline()
    with render, store, mock.patch("khatir.core.storage.signed_url", return_value="https://x/y"):
        client.post(_generate_url(tenant.pk), {}, format="json")

    assert AuditEntry.objects.filter(action="dmpform.generate").count() == 1


def test_unauthenticated_rejected() -> None:
    api = APIClient()
    resp = api.post(_generate_url(1), {}, format="json")
    assert resp.status_code in (status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN)


# ── owner scoping (cross-user 404) ────────────────────────────────────────────


def test_scoped_generate_other_owner_404(client: APIClient) -> None:
    """A tenant the requester does not own (foreign lease) resolves to 404."""
    other = UserFactory(phone="+8801712349999", role=Role.LANDLORD)
    foreign_tenant = _owned_tenant(other)  # type: ignore[arg-type]

    render, store = _mock_pipeline()
    with render, store, mock.patch("khatir.core.storage.signed_url", return_value="https://x/y"):
        resp = client.post(_generate_url(foreign_tenant.pk), {}, format="json")

    assert resp.status_code == status.HTTP_404_NOT_FOUND
    assert DMPFormRecord.objects.count() == 0


def test_scoped_unleased_tenant_404(client: APIClient) -> None:
    """A tenant with no lease at all is invisible to every owner → 404."""
    orphan: Tenant = TenantFactory(name="Orphan")  # type: ignore[assignment]
    render, store = _mock_pipeline()
    with render, store, mock.patch("khatir.core.storage.signed_url", return_value="https://x/y"):
        resp = client.post(_generate_url(orphan.pk), {}, format="json")
    assert resp.status_code == status.HTTP_404_NOT_FOUND


# ── record retrieval ───────────────────────────────────────────────────────


def test_get_record_owner(client: APIClient, landlord: User) -> None:
    tenant = _owned_tenant(landlord)
    record: DMPFormRecord = DMPFormRecordFactory(  # type: ignore[assignment]
        tenant=tenant, generated_by=landlord
    )
    with mock.patch("khatir.core.storage.signed_url", return_value="https://x/fresh"):
        resp = client.get(_record_url(record.pk))

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data["id"] == record.pk
    assert resp.data["signed_url"] == "https://x/fresh"


def test_get_record_other_owner_404(client: APIClient) -> None:
    other = UserFactory(phone="+8801712348888", role=Role.LANDLORD)
    foreign_tenant = _owned_tenant(other)  # type: ignore[arg-type]
    record: DMPFormRecord = DMPFormRecordFactory(tenant=foreign_tenant)  # type: ignore[assignment]

    resp = client.get(_record_url(record.pk))
    assert resp.status_code == status.HTTP_404_NOT_FOUND
