"""API + scoping tests for the manager consolidated dashboard (T-004 §12).

Exercises ``GET /api/v1/manager/dashboard`` through DRF's ``APIClient`` with a
real authenticated manager. Covers the consolidated shape (per-owner rows + a
summed total), active-link scoping (only owners with an **active** link
contribute; pending/revoked links and other managers' owners never appear),
the ``months`` query param, per-manager short caching, role gating, and the
``b2b_manager_enabled`` feature-flag gate.
"""

from __future__ import annotations

from decimal import Decimal

import pytest
from django.core.cache import cache
from rest_framework import status
from rest_framework.test import APIClient

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.featureflags.enums import FlagScope
from khatir.featureflags.models import FeatureFlag
from khatir.leases.enums import LeaseStatus, RentScheduleStatus
from khatir.leases.tests.factories import LeaseFactory, RentScheduleFactory
from khatir.managers.enums import ManagerOwnerLinkStatus
from khatir.properties.enums import UnitStatus
from khatir.properties.tests.factories import BuildingFactory, UnitFactory

from .factories import ManagerOwnerLinkFactory

pytestmark = pytest.mark.django_db

URL = "/api/v1/manager/dashboard"


@pytest.fixture(autouse=True)
def _flag_on() -> None:
    FeatureFlag.objects.create(
        key="b2b_manager_enabled", scope=FlagScope.GLOBAL, enabled=True
    )


@pytest.fixture(autouse=True)
def _clear_cache() -> None:
    cache.clear()


@pytest.fixture
def manager() -> User:
    return UserFactory(role=Role.MANAGER)  # type: ignore[return-value]


@pytest.fixture
def client(manager: User) -> APIClient:
    api = APIClient()
    api.force_authenticate(user=manager)
    return api


def _owner() -> User:
    return UserFactory(role=Role.LANDLORD)  # type: ignore[return-value]


def _occupied_unit(owner: User) -> object:
    building = BuildingFactory(owner=owner)
    return UnitFactory(building=building, status=UnitStatus.OCCUPIED)


def _paid_rent(owner: User, amount: str, period: str = "2026-05") -> None:
    unit = _occupied_unit(owner)
    lease = LeaseFactory(landlord=owner, unit=unit, status=LeaseStatus.ACTIVE)
    RentScheduleFactory(
        lease=lease,
        period=period,
        amount=Decimal(amount),
        status=RentScheduleStatus.PAID,
    )


def _link(manager: User, owner: User, status_: str) -> None:
    ManagerOwnerLinkFactory(manager=manager, owner=owner, status=status_)


def test_dashboard_sums_active_linked_owners(
    client: APIClient, manager: User
) -> None:
    """Per-owner rows plus a summed total over active-linked owners."""
    owner_a = _owner()
    owner_b = _owner()
    _paid_rent(owner_a, "10000.00")
    _paid_rent(owner_b, "5000.00")
    _link(manager, owner_a, ManagerOwnerLinkStatus.ACTIVE)
    _link(manager, owner_b, ManagerOwnerLinkStatus.ACTIVE)

    resp = client.get(URL)

    assert resp.status_code == status.HTTP_200_OK
    body = resp.json()
    assert body["owner_count"] == 2
    assert {row["owner_id"] for row in body["owners"]} == {
        owner_a.pk,
        owner_b.pk,
    }
    assert body["total"]["total_collected"] == "15000.00"
    assert body["total"]["total_units"] == 2
    assert body["total"]["occupied_units"] == 2
    # Rate recomputed from the summed parts (100% collected, no pending/overdue).
    assert body["total"]["collection_rate"] == 100.0
    assert body["total"]["occupancy_rate"] == 100.0


def test_pending_and_revoked_links_excluded(
    client: APIClient, manager: User
) -> None:
    """Only owners with an *active* link contribute; others never appear."""
    active_owner = _owner()
    pending_owner = _owner()
    revoked_owner = _owner()
    _paid_rent(active_owner, "10000.00")
    _paid_rent(pending_owner, "77777.00")
    _paid_rent(revoked_owner, "88888.00")
    _link(manager, active_owner, ManagerOwnerLinkStatus.ACTIVE)
    _link(manager, pending_owner, ManagerOwnerLinkStatus.PENDING)
    _link(manager, revoked_owner, ManagerOwnerLinkStatus.REVOKED)

    body = client.get(URL).json()

    assert body["owner_count"] == 1
    assert [row["owner_id"] for row in body["owners"]] == [active_owner.pk]
    assert body["total"]["total_collected"] == "10000.00"


def test_other_managers_owner_excluded(
    client: APIClient, manager: User
) -> None:
    """A different manager's active link never leaks into this dashboard."""
    other_manager = UserFactory(role=Role.MANAGER)
    other_owner = _owner()
    _paid_rent(other_owner, "99999.00")
    _link(other_manager, other_owner, ManagerOwnerLinkStatus.ACTIVE)

    body = client.get(URL).json()

    assert body["owner_count"] == 0
    assert body["owners"] == []
    assert body["total"]["total_collected"] == "0.00"


def test_no_active_links_empty_payload(client: APIClient) -> None:
    """A manager with no active links gets an empty, all-zero payload."""
    body = client.get(URL).json()

    assert body["owner_count"] == 0
    assert body["owners"] == []
    assert body["total"]["total_collected"] == "0.00"
    assert body["total"]["total_units"] == 0
    assert body["total"]["collection_rate"] == 0.0


def test_months_param_controls_series_length(
    client: APIClient, manager: User
) -> None:
    """``months`` controls each owner's (and the total's) series length."""
    owner = _owner()
    _paid_rent(owner, "1000.00")
    _link(manager, owner, ManagerOwnerLinkStatus.ACTIVE)

    body = client.get(URL, {"months": 3}).json()

    assert len(body["total"]["monthly_series"]) == 3
    assert len(body["owners"][0]["metrics"]["monthly_series"]) == 3


def test_cached_per_manager(client: APIClient, manager: User) -> None:
    """Payload is cached per manager; a later write is unseen until TTL."""
    owner = _owner()
    _link(manager, owner, ManagerOwnerLinkStatus.ACTIVE)

    first = client.get(URL).json()
    assert first["total"]["total_collected"] == "0.00"

    _paid_rent(owner, "4321.00")
    cached = client.get(URL).json()
    assert cached["total"]["total_collected"] == "0.00"  # from cache

    cache.clear()
    fresh = client.get(URL).json()
    assert fresh["total"]["total_collected"] == "4321.00"


def test_landlord_role_forbidden() -> None:
    """A landlord cannot read the manager consolidated dashboard."""
    api = APIClient()
    api.force_authenticate(user=UserFactory(role=Role.LANDLORD))
    assert api.get(URL).status_code == status.HTTP_403_FORBIDDEN


def test_requires_auth() -> None:
    resp = APIClient().get(URL)
    assert resp.status_code in (
        status.HTTP_401_UNAUTHORIZED,
        status.HTTP_403_FORBIDDEN,
    )


def test_flag_off_blocks_endpoint(client: APIClient) -> None:
    FeatureFlag.objects.filter(key="b2b_manager_enabled").update(enabled=False)
    assert client.get(URL).status_code == status.HTTP_403_FORBIDDEN
