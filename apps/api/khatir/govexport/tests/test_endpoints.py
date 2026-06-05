"""API tests for the gov-export endpoints (EPIC-26 T-004 §12).

Exercises ``POST /api/v1/gov-export`` and ``GET /api/v1/gov-export/{id}``
through DRF's ``APIClient``. Render and storage are **mocked** so the tests
assert orchestration (flag-gating, consent, owner-scoping, audit), not template
fidelity or real S3. Covers: flag default-off (403), flag-on happy path with a
signed URL, period validation, owner scoping (cross-landlord 404), the generate
+ download audit rows, and auth.
"""

from __future__ import annotations

import datetime
from unittest import mock

import pytest
from rest_framework import status
from rest_framework.test import APIClient

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.compliance.enums import ConsentType
from khatir.compliance.models import ConsentRecord
from khatir.core.models import AuditEntry
from khatir.featureflags.enums import FlagScope
from khatir.featureflags.models import FeatureFlag
from khatir.govexport.models import GovExport
from khatir.leases.enums import LeaseStatus
from khatir.leases.tests.factories import LeaseFactory
from khatir.tenants.tests.factories import TenantFactory

from .factories import GovExportFactory

pytestmark = pytest.mark.django_db

PERIOD = "2026-05"
GENERATE_URL = "/api/v1/gov-export"


def _detail_url(export_id: object) -> str:
    return f"/api/v1/gov-export/{export_id}"


@pytest.fixture
def landlord() -> User:
    created: User = UserFactory(role=Role.LANDLORD)  # type: ignore[assignment]
    return created


@pytest.fixture
def client(landlord: User) -> APIClient:
    api = APIClient()
    api.force_authenticate(user=landlord)
    return api


def _enable_flag(enabled: bool = True) -> None:
    FeatureFlag.objects.update_or_create(
        key="gov_export_enabled",
        defaults={"scope": FlagScope.GLOBAL, "enabled": enabled},
    )


def _consented_tenant(landlord: User) -> object:
    """A consenting tenant on an active lease for ``landlord`` covering PERIOD."""
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
    return tenant


def _mock_pipeline():
    """Patch the render + storage seams the builder orchestrates."""
    return (
        mock.patch("khatir.govexport.builder.render_dmp_pdf", return_value=b"%PDF fake"),
        mock.patch("khatir.core.storage.store_encrypted", return_value="gov_export/x.zip"),
        mock.patch("khatir.core.storage.signed_url", return_value="https://x/dl?sig=a"),
    )


# ── flag gating ──────────────────────────────────────────────────────────────


def test_generate_flag_off_is_403(client: APIClient, landlord: User) -> None:
    """Default OFF: with no flag row configured, generate is forbidden."""
    resp = client.post(GENERATE_URL, {"period": PERIOD}, format="json")
    assert resp.status_code == status.HTTP_403_FORBIDDEN
    assert GovExport.objects.count() == 0


def test_generate_flag_explicitly_off_is_403(client: APIClient) -> None:
    _enable_flag(enabled=False)
    resp = client.post(GENERATE_URL, {"period": PERIOD}, format="json")
    assert resp.status_code == status.HTTP_403_FORBIDDEN


def test_detail_flag_off_is_403(client: APIClient, landlord: User) -> None:
    export = GovExportFactory(landlord=landlord)
    resp = client.get(_detail_url(export.pk))
    assert resp.status_code == status.HTTP_403_FORBIDDEN


# ── generate happy path ───────────────────────────────────────────────────────


def test_generate_returns_signed_url_and_row(client: APIClient, landlord: User) -> None:
    _enable_flag()
    _consented_tenant(landlord)
    render, store, signed = _mock_pipeline()
    with render, store, signed:
        resp = client.post(GENERATE_URL, {"period": PERIOD}, format="json")

    assert resp.status_code == status.HTTP_201_CREATED
    assert resp.data["signed_url"] == "https://x/dl?sig=a"
    assert resp.data["export"]["period"] == PERIOD
    assert resp.data["export"]["record_count"] == 1
    assert resp.data["export"]["file_ref"] == "gov_export/x.zip"

    export = GovExport.objects.get(pk=resp.data["export"]["id"])
    assert export.landlord_id == landlord.pk


def test_generate_writes_audit(client: APIClient, landlord: User) -> None:
    _enable_flag()
    _consented_tenant(landlord)
    render, store, signed = _mock_pipeline()
    with render, store, signed:
        client.post(GENERATE_URL, {"period": PERIOD}, format="json")

    assert AuditEntry.objects.filter(action="govexport.generate").count() == 1


def test_generate_excludes_non_consenting(client: APIClient, landlord: User) -> None:
    """A tenant without data-sharing consent is not in the package (count 0)."""
    _enable_flag()
    tenant = TenantFactory(linked_user=UserFactory(role=Role.TENANT))
    LeaseFactory(
        landlord=landlord,
        tenant=tenant,
        start_date=datetime.date(2026, 1, 1),
        end_date=datetime.date(2026, 12, 31),
        status=LeaseStatus.ACTIVE,
    )
    render, store, signed = _mock_pipeline()
    with render, store, signed:
        resp = client.post(GENERATE_URL, {"period": PERIOD}, format="json")

    assert resp.status_code == status.HTTP_201_CREATED
    assert resp.data["export"]["record_count"] == 0


# ── period validation ─────────────────────────────────────────────────────────


@pytest.mark.parametrize("bad", ["2026-13", "2026/05", "26-05", "2026", "", "2026-00"])
def test_generate_rejects_bad_period(client: APIClient, bad: str) -> None:
    _enable_flag()
    resp = client.post(GENERATE_URL, {"period": bad}, format="json")
    assert resp.status_code == status.HTTP_400_BAD_REQUEST
    assert GovExport.objects.count() == 0


def test_generate_requires_period(client: APIClient) -> None:
    _enable_flag()
    resp = client.post(GENERATE_URL, {}, format="json")
    assert resp.status_code == status.HTTP_400_BAD_REQUEST


# ── detail / download ──────────────────────────────────────────────────────────


def test_detail_returns_fresh_signed_url(client: APIClient, landlord: User) -> None:
    _enable_flag()
    export = GovExportFactory(landlord=landlord)
    with mock.patch("khatir.core.storage.signed_url", return_value="https://x/fresh"):
        resp = client.get(_detail_url(export.pk))

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data["id"] == export.pk
    assert resp.data["signed_url"] == "https://x/fresh"


def test_detail_writes_download_audit(client: APIClient, landlord: User) -> None:
    _enable_flag()
    export = GovExportFactory(landlord=landlord)
    with mock.patch("khatir.core.storage.signed_url", return_value="https://x/fresh"):
        client.get(_detail_url(export.pk))

    assert AuditEntry.objects.filter(action="govexport.download").count() == 1


def test_detail_other_landlord_404(client: APIClient) -> None:
    """An export owned by another landlord is invisible → 404."""
    _enable_flag()
    other = UserFactory(role=Role.LANDLORD)
    export = GovExportFactory(landlord=other)
    resp = client.get(_detail_url(export.pk))
    assert resp.status_code == status.HTTP_404_NOT_FOUND


def test_detail_unknown_404(client: APIClient) -> None:
    _enable_flag()
    resp = client.get(_detail_url(999999))
    assert resp.status_code == status.HTTP_404_NOT_FOUND


# ── auth + role gating ─────────────────────────────────────────────────────────


def test_generate_unauthenticated_rejected() -> None:
    api = APIClient()
    resp = api.post(GENERATE_URL, {"period": PERIOD}, format="json")
    assert resp.status_code in (status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN)


def test_generate_tenant_role_rejected() -> None:
    _enable_flag()
    api = APIClient()
    api.force_authenticate(user=UserFactory(role=Role.TENANT))
    resp = api.post(GENERATE_URL, {"period": PERIOD}, format="json")
    assert resp.status_code == status.HTTP_403_FORBIDDEN
