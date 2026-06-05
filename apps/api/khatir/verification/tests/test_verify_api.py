"""API tests for the verify endpoint (EPIC-17 T-004 §12).

Drives ``POST /api/v1/tenants/{id}/verify`` and ``GET .../verification`` through
DRF's ``APIClient`` with the EC provider mocked (no real vendor HTTP). Covers the
strict gate order (§15): tier → flag → owner-scope → consent → check, plus the
boolean-only outcomes (matched / not_matched), the persisted append-only log, the
tenant status transition, and the privacy guarantee that no raw EC field / NID
crosses the boundary.
"""

from __future__ import annotations

from collections.abc import Iterator
from typing import Any
from unittest import mock

import pytest
from rest_framework import status
from rest_framework.test import APIClient

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.billing.enums import SubscriptionStatus
from khatir.billing.tests.factories import PricingTierFactory, SubscriptionFactory
from khatir.compliance.enums import ConsentType
from khatir.compliance.models import ConsentRecord
from khatir.core.models import AuditEntry
from khatir.leases.tests.factories import LeaseFactory
from khatir.properties.tests.factories import BuildingFactory, UnitFactory
from khatir.tenants.enums import VerificationStatus
from khatir.tenants.models import Tenant
from khatir.tenants.tests.factories import TenantFactory
from khatir.verification.enums import VerificationResult
from khatir.verification.models import VerificationLog
from khatir.verification.providers import VerificationOutcome

pytestmark = pytest.mark.django_db

PROVIDER_FACTORY = "khatir.verification.services.get_verification_provider"


# --- fixtures ----------------------------------------------------------------


@pytest.fixture
def landlord() -> User:
    return UserFactory(role=Role.LANDLORD)  # type: ignore[return-value]


def _grant_verification(user: User) -> None:
    """Put ``user`` on a paid tier that bundles NID verification (T-009 gate)."""
    tier = PricingTierFactory(includes_verification=True)
    SubscriptionFactory(user=user, tier=tier, status=SubscriptionStatus.ACTIVE)


@pytest.fixture
def verified_landlord(landlord: User) -> User:
    _grant_verification(landlord)
    return landlord


@pytest.fixture
def tenant(verified_landlord: User) -> Tenant:
    """A tenant holding a lease on a unit the verified landlord owns (in scope)."""
    obj: Tenant = TenantFactory()  # type: ignore[assignment]
    obj.set_nid("1990123456789")
    obj.dob = __import__("datetime").date(1990, 1, 15)
    obj.save()
    building = BuildingFactory(owner=verified_landlord)
    unit = UnitFactory(building=building)
    LeaseFactory(unit=unit, tenant=obj, landlord=verified_landlord)
    return obj


@pytest.fixture
def client(verified_landlord: User) -> APIClient:
    api = APIClient()
    api.force_authenticate(user=verified_landlord)
    return api


def _verify_path(tenant: Tenant) -> str:
    return f"/api/v1/tenants/{tenant.pk}/verify"


def _result_path(tenant: Tenant) -> str:
    return f"/api/v1/tenants/{tenant.pk}/verification"


def _mock_provider(outcome: VerificationOutcome) -> Any:
    """Context manager patching the provider factory to return ``outcome``."""
    provider = mock.Mock()
    provider.verify.return_value = outcome
    return mock.patch(PROVIDER_FACTORY, return_value=provider)


@pytest.fixture(autouse=True)
def _no_flag_rows() -> Iterator[None]:
    """No FeatureFlag rows by default → ``nid_verification_enabled`` defaults on."""
    yield


# --- happy path: matched / not_matched ---------------------------------------


def test_verify_matched(client: APIClient, tenant: Tenant) -> None:
    outcome = VerificationOutcome.matched_result(provider_ref="ec-txn-1")
    with _mock_provider(outcome):
        resp = client.post(_verify_path(tenant))

    assert resp.status_code == status.HTTP_200_OK
    body = resp.json()
    assert body["result"] == VerificationResult.MATCHED
    assert body["date"] is not None
    # Only the boolean shape crosses the boundary — no raw EC / NID / provider_ref.
    assert set(body) == {"result", "date"}

    tenant.refresh_from_db()
    assert tenant.verification_status == VerificationStatus.MATCHED
    assert tenant.verified_at is not None

    log = VerificationLog.objects.get(tenant=tenant)
    assert log.result == VerificationResult.MATCHED
    assert log.provider_ref == "ec-txn-1"
    assert log.requested_by_id is not None
    # Consent was captured and linked.
    assert log.consent_record.consent_type == ConsentType.PDPA_NID_VERIFICATION


def test_verify_not_matched(client: APIClient, tenant: Tenant) -> None:
    with _mock_provider(VerificationOutcome.not_matched_result(provider_ref="ec-2")):
        resp = client.post(_verify_path(tenant))

    assert resp.status_code == status.HTTP_200_OK
    assert resp.json()["result"] == VerificationResult.NOT_MATCHED

    tenant.refresh_from_db()
    assert tenant.verification_status == VerificationStatus.NOT_MATCHED
    assert tenant.verified_at is None


def test_verify_passes_decrypted_nid_to_provider(
    client: APIClient, tenant: Tenant
) -> None:
    """The provider receives the plaintext NID + name + DOB (audited decrypt path)."""
    provider = mock.Mock()
    provider.verify.return_value = VerificationOutcome.matched_result()
    with mock.patch(PROVIDER_FACTORY, return_value=provider):
        client.post(_verify_path(tenant))

    provider.verify.assert_called_once_with(
        nid="1990123456789", name=tenant.name, dob="1990-01-15"
    )
    # The decrypt is audited; the raw NID is never written into the audit payload.
    decrypt_entry = AuditEntry.objects.filter(action="tenant.nid.decrypt").first()
    assert decrypt_entry is not None
    assert "1990123456789" not in str(decrypt_entry.after)


def test_verify_audited(client: APIClient, tenant: Tenant) -> None:
    with _mock_provider(VerificationOutcome.matched_result(provider_ref="ec-9")):
        client.post(_verify_path(tenant))

    entry = AuditEntry.objects.filter(action="verification.verify").first()
    assert entry is not None
    assert entry.after["result"] == VerificationResult.MATCHED
    # No raw EC field / NID leaks into the audit row.
    assert "1990123456789" not in str(entry.after)


# --- gate: tier --------------------------------------------------------------


def test_free_tier_blocked(landlord: User, tenant: Tenant) -> None:
    """A landlord without a verification tier is blocked before any provider call."""
    # Drop the verification subscription granted by the ``tenant`` fixture.
    landlord.subscriptions.all().delete()
    api = APIClient()
    api.force_authenticate(user=landlord)

    with _mock_provider(VerificationOutcome.matched_result()) as provider_factory:
        resp = api.post(_verify_path(tenant))

    assert resp.status_code == status.HTTP_402_PAYMENT_REQUIRED
    assert resp.json()["error"]["code"] == "feature_requires_upgrade"
    provider_factory.assert_not_called()
    # No log written, status untouched.
    assert not VerificationLog.objects.filter(tenant=tenant).exists()


# --- gate: flag --------------------------------------------------------------


def test_flag_off(client: APIClient, tenant: Tenant) -> None:
    """``nid_verification_enabled`` off → feature_disabled (403), no provider call."""
    from khatir.featureflags.enums import FlagScope
    from khatir.featureflags.models import FeatureFlag

    FeatureFlag.objects.create(
        key="nid_verification_enabled", scope=FlagScope.GLOBAL, enabled=False
    )

    with _mock_provider(VerificationOutcome.matched_result()) as provider_factory:
        resp = client.post(_verify_path(tenant))

    assert resp.status_code == status.HTTP_403_FORBIDDEN
    assert resp.json()["error"]["code"] == "feature_disabled"
    provider_factory.assert_not_called()
    assert not VerificationLog.objects.filter(tenant=tenant).exists()


# --- gate: owner scope -------------------------------------------------------


def test_foreign_tenant_404(client: APIClient, verified_landlord: User) -> None:
    """A tenant the caller cannot see → 404 (never reveal existence)."""
    other = TenantFactory()  # no lease on any of the caller's units
    with _mock_provider(VerificationOutcome.matched_result()):
        resp = client.post(_verify_path(other))
    assert resp.status_code == status.HTTP_404_NOT_FOUND


def test_requires_landlord_or_manager(tenant: Tenant) -> None:
    tenant_user = UserFactory(role=Role.TENANT)
    api = APIClient()
    api.force_authenticate(user=tenant_user)
    with _mock_provider(VerificationOutcome.matched_result()):
        resp = api.post(_verify_path(tenant))
    assert resp.status_code == status.HTTP_403_FORBIDDEN


def test_unauthenticated_rejected(tenant: Tenant) -> None:
    resp = APIClient().post(_verify_path(tenant))
    assert resp.status_code in (
        status.HTTP_401_UNAUTHORIZED,
        status.HTTP_403_FORBIDDEN,
    )


# --- consent -----------------------------------------------------------------


def test_consent_recorded_on_verify(client: APIClient, tenant: Tenant) -> None:
    assert not ConsentRecord.objects.filter(
        consent_type=ConsentType.PDPA_NID_VERIFICATION
    ).exists()

    with _mock_provider(VerificationOutcome.matched_result()):
        client.post(_verify_path(tenant))

    consent = ConsentRecord.objects.get(
        consent_type=ConsentType.PDPA_NID_VERIFICATION
    )
    assert consent.granted_at is not None
    assert consent.revoked_at is None


# --- GET last verification ---------------------------------------------------


def test_get_verification_after_verify(client: APIClient, tenant: Tenant) -> None:
    with _mock_provider(VerificationOutcome.matched_result(provider_ref="ec-7")):
        client.post(_verify_path(tenant))

    resp = client.get(_result_path(tenant))
    assert resp.status_code == status.HTTP_200_OK
    body = resp.json()
    assert body["result"] == VerificationResult.MATCHED
    assert set(body) == {"result", "date"}


def test_get_verification_none_when_never_run(
    client: APIClient, tenant: Tenant
) -> None:
    resp = client.get(_result_path(tenant))
    assert resp.status_code == status.HTTP_200_OK
    assert resp.json() == {"result": None, "date": None}


def test_get_verification_foreign_tenant_404(
    client: APIClient, verified_landlord: User
) -> None:
    other = TenantFactory()
    resp = client.get(_result_path(other))
    assert resp.status_code == status.HTTP_404_NOT_FOUND
