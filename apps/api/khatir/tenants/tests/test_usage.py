"""Free-tier counter tests (T-008 §12).

Exercises the ``tenant_usage`` selector and the ``GET /api/v1/usage`` endpoint:
an accurate count scoped to the caller, the free limit pulled from
``SystemConfig`` (not hardcoded), and the ``is_over_free`` soft signal flipping
once the count exceeds the limit. Crossing the limit must **not** block tenant
creation — enforcement is EPIC-10 (T-008 §15).
"""

from __future__ import annotations

import pytest
from rest_framework import status
from rest_framework.test import APIClient

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.core.config import invalidate_config
from khatir.core.models import SystemConfig
from khatir.leases.tests.factories import LeaseFactory
from khatir.properties.tests.factories import BuildingFactory, UnitFactory
from khatir.tenants.tests.factories import TenantFactory
from khatir.tenants.usage import FREE_TIER_LIMIT_KEY, tenant_usage

pytestmark = pytest.mark.django_db


@pytest.fixture
def landlord() -> User:
    created: User = UserFactory(  # type: ignore[assignment]
        phone="+8801712345678", name="Landlord", role=Role.LANDLORD
    )
    return created


@pytest.fixture
def client(landlord: User) -> APIClient:
    api = APIClient()
    api.force_authenticate(user=landlord)
    return api


def _give_tenant(user: User) -> None:
    """Lease a fresh tenant onto a unit in a building ``user`` owns."""
    tenant = TenantFactory()
    building = BuildingFactory(owner=user)
    unit = UnitFactory(building=building)
    LeaseFactory(unit=unit, tenant=tenant, landlord=user)


def _set_free_limit(value: int) -> None:
    SystemConfig.objects.update_or_create(
        key=FREE_TIER_LIMIT_KEY,
        defaults={"value": str(value), "type": "int", "description": "test"},
    )
    invalidate_config(FREE_TIER_LIMIT_KEY)


# --- selector ----------------------------------------------------------------


def test_count_starts_at_zero(landlord: User) -> None:
    usage = tenant_usage(landlord)
    assert usage.tenants_used == 0
    assert usage.free_limit == 2
    assert usage.is_over_free is False


def test_count_reflects_leased_tenants(landlord: User) -> None:
    _give_tenant(landlord)
    _give_tenant(landlord)

    usage = tenant_usage(landlord)
    assert usage.tenants_used == 2
    # At exactly the limit the user is still within the free tier.
    assert usage.is_over_free is False


def test_over_free_when_exceeds(landlord: User) -> None:
    for _ in range(3):
        _give_tenant(landlord)

    usage = tenant_usage(landlord)
    assert usage.tenants_used == 3
    assert usage.is_over_free is True


def test_count_is_scoped_to_caller(landlord: User) -> None:
    other: User = UserFactory(  # type: ignore[assignment]
        phone="+8801799999999", name="Other", role=Role.LANDLORD
    )
    _give_tenant(other)
    _give_tenant(other)
    _give_tenant(landlord)

    # The caller's count never includes another landlord's tenants.
    assert tenant_usage(landlord).tenants_used == 1
    assert tenant_usage(other).tenants_used == 2


def test_free_limit_read_from_config_not_hardcoded(landlord: User) -> None:
    _set_free_limit(3)
    for _ in range(3):
        _give_tenant(landlord)

    usage = tenant_usage(landlord)
    assert usage.free_limit == 3
    # 3 tenants at a limit of 3 is no longer over the free tier.
    assert usage.is_over_free is False


# --- endpoint ----------------------------------------------------------------


def test_usage_endpoint_returns_fields(client: APIClient, landlord: User) -> None:
    _give_tenant(landlord)

    resp = client.get("/api/v1/usage")

    assert resp.status_code == status.HTTP_200_OK
    body = resp.json()
    assert body == {"tenants_used": 1, "free_limit": 2, "is_over_free": False}


def test_usage_endpoint_over_free(client: APIClient, landlord: User) -> None:
    for _ in range(3):
        _give_tenant(landlord)

    body = client.get("/api/v1/usage").json()
    assert body["tenants_used"] == 3
    assert body["is_over_free"] is True


def test_usage_endpoint_requires_auth() -> None:
    resp = APIClient().get("/api/v1/usage")
    assert resp.status_code in (
        status.HTTP_401_UNAUTHORIZED,
        status.HTTP_403_FORBIDDEN,
    )
