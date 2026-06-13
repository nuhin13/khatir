"""Tests for the platform dashboard endpoint (EPIC-11.T-005 §12).

Covers: every KPI present + correctly aggregated across all users; admin-only
access (token required, only platform-section roles); the 5-minute cache; and a
live ``health`` block. Admin auth here is the dedicated admin JWT realm
(``ADMIN_JWT_SIGNING_KEY``) — fully separate from the customer JWT.
"""

from __future__ import annotations

from decimal import Decimal
from typing import Any

import jwt
import pytest
from django.conf import settings
from django.core.cache import cache
from rest_framework.test import APIClient

from khatir.admin_portal import dashboard as dashboard_module
from khatir.billing.enums import SubscriptionStatus
from khatir.billing.tests.factories import SubscriptionFactory
from khatir.core.enums import AdminRole, Role
from khatir.dmpforms.tests.factories import DMPFormRecordFactory
from khatir.properties.enums import UnitStatus
from khatir.properties.models import Building, Unit
from khatir.properties.tests.factories import BuildingFactory, UnitFactory
from khatir.rent.tests.factories import PaymentFactory, RentRequestFactory

DASHBOARD_URL = "/admin/api/dashboard"

pytestmark = pytest.mark.django_db


def _mint(role: str = AdminRole.OPS, admin_user_id: Any = 1) -> str:
    """Sign an admin JWT for the committed T-004 permission layer."""
    return jwt.encode(
        {"admin_user_id": admin_user_id, "role": role},
        settings.ADMIN_JWT_SIGNING_KEY,
        algorithm="HS256",
    )


def _auth_client(role: str = AdminRole.OPS) -> APIClient:
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {_mint(role)}")
    return client


# --- KPI presence + aggregation --------------------------------------------


def test_platform_kpis_present() -> None:
    body = _auth_client().get(DASHBOARD_URL).json()
    for key in (
        "total_users",
        "active_landlords",
        "total_properties",
        "total_units",
        "occupied_units",
        "total_rent_collected",
        "dmp_forms_generated",
        "active_subscriptions",
        "health",
    ):
        assert key in body, f"missing KPI: {key}"
    assert {"all_time", "this_month"} <= set(body["total_rent_collected"])


def test_kpis_aggregate_across_all_users() -> None:
    # Two landlords, each with a building + units (one occupied, one vacant).
    b1 = BuildingFactory()
    b2 = BuildingFactory()
    UnitFactory(building=b1, status=UnitStatus.OCCUPIED)
    UnitFactory(building=b1, status=UnitStatus.VACANT)
    UnitFactory(building=b2, status=UnitStatus.OCCUPIED)

    # Rent collected: one verified payment of 15000. (Its lease/unit/building
    # chain adds rows too, so assert against live model counts rather than
    # hard-coded totals.)
    req = RentRequestFactory(amount=Decimal("15000.00"))
    PaymentFactory(rent_request=req)

    DMPFormRecordFactory()
    DMPFormRecordFactory()
    SubscriptionFactory(status=SubscriptionStatus.ACTIVE)
    SubscriptionFactory(status=SubscriptionStatus.CANCELLED)

    body = _auth_client(AdminRole.SUPER).get(DASHBOARD_URL).json()

    assert body["total_properties"] == Building.objects.count()
    assert body["active_landlords"] == (
        Building.objects.filter(owner__role=Role.LANDLORD)
        .values("owner_id")
        .distinct()
        .count()
    )
    assert body["total_units"] == Unit.objects.count()
    assert body["occupied_units"] == 2
    assert body["dmp_forms_generated"] == 2
    assert body["active_subscriptions"] == 1
    assert body["total_rent_collected"]["all_time"] == "15000.00"
    assert body["total_rent_collected"]["this_month"] == "15000.00"


def test_health_block_reports_status() -> None:
    body = _auth_client().get(DASHBOARD_URL).json()
    health = body["health"]
    assert health["app"] == "ok"
    assert health["database"] == "ok"
    assert health["cache"] == "ok"
    assert health["status"] == "ok"


# --- Auth / scoping ----------------------------------------------------------


def test_admin_only_rejects_anonymous() -> None:
    resp = APIClient().get(DASHBOARD_URL)
    assert resp.status_code in (401, 403)


def test_admin_only_rejects_invalid_token() -> None:
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION="Bearer not-a-real-token")
    assert client.get(DASHBOARD_URL).status_code in (401, 403)


@pytest.mark.parametrize("role", [AdminRole.SUPER, AdminRole.OPS])
def test_platform_roles_allowed(role: str) -> None:
    assert _auth_client(role).get(DASHBOARD_URL).status_code == 200


@pytest.mark.parametrize(
    "role", [AdminRole.FINANCE, AdminRole.COMPLIANCE, AdminRole.SUPPORT]
)
def test_non_platform_roles_denied(role: str) -> None:
    assert _auth_client(role).get(DASHBOARD_URL).status_code == 403


def test_customer_role_token_denied() -> None:
    # A customer-realm role value must never satisfy the admin layer.
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {_mint(role=Role.LANDLORD)}")
    assert client.get(DASHBOARD_URL).status_code in (401, 403)


# --- Caching -----------------------------------------------------------------


def test_kpis_cached_5_min() -> None:
    client = _auth_client()
    BuildingFactory()
    first = client.get(DASHBOARD_URL).json()
    assert first["total_properties"] == 1

    # A second building should NOT change the response until the cache expires.
    BuildingFactory()
    second = client.get(DASHBOARD_URL).json()
    assert second["total_properties"] == 1

    # After clearing the cache the new count is reflected.
    cache.delete(dashboard_module.CACHE_KEY)
    third = client.get(DASHBOARD_URL).json()
    assert third["total_properties"] == 2
