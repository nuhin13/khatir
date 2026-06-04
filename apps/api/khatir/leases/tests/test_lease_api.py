"""API tests for the leases CRUD + lifecycle endpoints (T-003 §12).

Exercises ``/api/v1/leases`` through DRF's ``APIClient`` with real authenticated
landlords. Covers create-as-draft, the landlord-is-server-derived guarantee,
activation generating the rent schedule, the no-overlapping-active-lease guard,
terminate, audit writes, role gating, and the cross-user **404** (foreign leases
and units are invisible, never 403, T-003 §15).
"""

from __future__ import annotations

import datetime
from decimal import Decimal

import pytest
from rest_framework import status
from rest_framework.test import APIClient

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.core.models import AuditEntry
from khatir.leases.enums import LeaseStatus
from khatir.leases.models import Lease, RentSchedule
from khatir.properties.tests.factories import BuildingFactory, UnitFactory
from khatir.tenants.tests.factories import TenantFactory

from .factories import LeaseFactory

pytestmark = pytest.mark.django_db

LEASES_URL = "/api/v1/leases"


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


def _detail(pk: object) -> str:
    return f"{LEASES_URL}/{pk}"


def _create_body(unit_id: object, tenant_id: object) -> dict[str, object]:
    return {
        "unit_id": str(unit_id),
        "tenant_id": str(tenant_id),
        "start_date": "2026-01-01",
        "end_date": "2026-12-31",
        "rent": "15000.00",
        "advance": "30000.00",
    }


# ── create ──────────────────────────────────────────────────────────────────


def test_create_draft(client: APIClient, landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))
    tenant = TenantFactory()

    resp = client.post(LEASES_URL, _create_body(unit.pk, tenant.pk), format="json")

    assert resp.status_code == status.HTTP_201_CREATED
    assert resp.data["status"] == LeaseStatus.DRAFT.value
    # Landlord is derived server-side from the unit's building owner.
    assert resp.data["landlord_id"] == str(landlord.pk)
    lease = Lease.objects.get(pk=resp.data["id"])
    assert lease.landlord_id == landlord.pk
    assert lease.unit_id == unit.pk
    assert lease.tenant_id == tenant.pk


def test_create_derives_landlord_not_from_client(client: APIClient, landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))
    tenant = TenantFactory()
    other: User = UserFactory(phone="+8801799999999", role=Role.LANDLORD)  # type: ignore[assignment]

    body = _create_body(unit.pk, tenant.pk)
    body["landlord_id"] = str(other.pk)  # should be ignored
    resp = client.post(LEASES_URL, body, format="json")

    assert resp.status_code == status.HTTP_201_CREATED
    lease = Lease.objects.get(pk=resp.data["id"])
    assert lease.landlord_id == landlord.pk


def test_create_writes_audit(client: APIClient, landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))
    tenant = TenantFactory()

    resp = client.post(LEASES_URL, _create_body(unit.pk, tenant.pk), format="json")

    entry = AuditEntry.objects.get(action="lease.create")
    assert entry.actor_id == landlord.pk
    assert entry.target_type == "leases.lease"
    assert entry.target_id == str(resp.data["id"])
    assert entry.before is None
    assert entry.after["status"] == LeaseStatus.DRAFT.value


def test_create_foreign_unit_404(client: APIClient) -> None:
    foreign_unit = UnitFactory()  # belongs to a different landlord
    tenant = TenantFactory()

    resp = client.post(
        LEASES_URL, _create_body(foreign_unit.pk, tenant.pk), format="json"
    )

    # 404, never 403 — we do not reveal the unit exists (T-003 §15).
    assert resp.status_code == status.HTTP_404_NOT_FOUND
    assert not Lease.objects.exists()


def test_create_end_before_start_rejected(client: APIClient, landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))
    tenant = TenantFactory()
    body = _create_body(unit.pk, tenant.pk)
    body["end_date"] = "2025-12-31"

    resp = client.post(LEASES_URL, body, format="json")

    assert resp.status_code == status.HTTP_400_BAD_REQUEST
    assert resp.data["error"]["code"] == "validation_error"


# ── auth / role ──────────────────────────────────────────────────────────────


def test_create_requires_auth() -> None:
    resp = APIClient().post(LEASES_URL, {}, format="json")
    assert resp.status_code == status.HTTP_401_UNAUTHORIZED


def test_tenant_role_forbidden() -> None:
    tenant_user: User = UserFactory(phone="+8801700000001", role=Role.TENANT)  # type: ignore[assignment]
    api = APIClient()
    api.force_authenticate(user=tenant_user)

    resp = api.get(LEASES_URL)

    assert resp.status_code == status.HTTP_403_FORBIDDEN


# ── list / retrieve (scoped) ──────────────────────────────────────────────────


def test_list_scoped_to_landlord(client: APIClient, landlord: User) -> None:
    mine = LeaseFactory(landlord=landlord)
    LeaseFactory()  # someone else's

    resp = client.get(LEASES_URL)

    assert resp.status_code == status.HTTP_200_OK
    ids = [row["id"] for row in resp.data["results"]]
    assert ids == [str(mine.pk)]
    assert resp.data["pagination"]["count"] == 1


def test_retrieve_other_users_lease_404(client: APIClient) -> None:
    other = LeaseFactory()  # belongs to a different landlord

    resp = client.get(_detail(other.pk))

    assert resp.status_code == status.HTTP_404_NOT_FOUND
    assert resp.data["error"]["code"] == "not_found"


# ── update (draft only) ────────────────────────────────────────────────────────


def test_update_draft(client: APIClient, landlord: User) -> None:
    lease = LeaseFactory(landlord=landlord, rent=Decimal("10000.00"))

    resp = client.patch(_detail(lease.pk), {"rent": "12000.00"}, format="json")

    assert resp.status_code == status.HTTP_200_OK
    lease.refresh_from_db()
    assert lease.rent == Decimal("12000.00")


def test_update_active_lease_rejected(client: APIClient, landlord: User) -> None:
    lease = LeaseFactory(landlord=landlord, status=LeaseStatus.ACTIVE)

    resp = client.patch(_detail(lease.pk), {"rent": "12000.00"}, format="json")

    assert resp.status_code == status.HTTP_400_BAD_REQUEST


# ── activate (generates schedule) ──────────────────────────────────────────────


def test_activate_generates_schedule(client: APIClient, landlord: User) -> None:
    lease = LeaseFactory(
        landlord=landlord,
        status=LeaseStatus.DRAFT,
        start_date=datetime.date(2026, 1, 1),
        end_date=datetime.date(2026, 6, 30),
        rent=Decimal("15000.00"),
    )

    resp = client.post(f"{_detail(lease.pk)}/activate", {}, format="json")

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data["status"] == LeaseStatus.ACTIVE.value
    schedule = RentSchedule.objects.filter(lease=lease).order_by("period")
    # Jan..Jun 2026 = 6 months.
    assert schedule.count() == 6
    first = schedule.first()
    assert first is not None
    assert first.period == "2026-01"
    assert first.amount == Decimal("15000.00")
    assert first.due_date == datetime.date(2026, 1, 5)  # default due day


def test_activate_writes_audit(client: APIClient, landlord: User) -> None:
    lease = LeaseFactory(
        landlord=landlord,
        status=LeaseStatus.DRAFT,
        start_date=datetime.date(2026, 1, 1),
        end_date=datetime.date(2026, 3, 31),
    )

    client.post(f"{_detail(lease.pk)}/activate", {}, format="json")

    entry = AuditEntry.objects.get(action="lease.activate")
    assert entry.actor_id == landlord.pk
    assert entry.before == {"status": LeaseStatus.DRAFT.value}
    assert entry.after == {"status": LeaseStatus.ACTIVE.value}


def test_activate_blocks_overlapping_active_lease(client: APIClient, landlord: User) -> None:
    unit = UnitFactory(building=BuildingFactory(owner=landlord))
    LeaseFactory(landlord=landlord, unit=unit, status=LeaseStatus.ACTIVE)
    draft = LeaseFactory(landlord=landlord, unit=unit, status=LeaseStatus.DRAFT)

    resp = client.post(f"{_detail(draft.pk)}/activate", {}, format="json")

    assert resp.status_code == status.HTTP_409_CONFLICT
    draft.refresh_from_db()
    assert draft.status == LeaseStatus.DRAFT.value
    assert not RentSchedule.objects.filter(lease=draft).exists()


def test_activate_non_draft_rejected(client: APIClient, landlord: User) -> None:
    lease = LeaseFactory(landlord=landlord, status=LeaseStatus.ACTIVE)

    resp = client.post(f"{_detail(lease.pk)}/activate", {}, format="json")

    assert resp.status_code == status.HTTP_400_BAD_REQUEST


def test_activate_foreign_lease_404(client: APIClient) -> None:
    other = LeaseFactory(status=LeaseStatus.DRAFT)

    resp = client.post(f"{_detail(other.pk)}/activate", {}, format="json")

    assert resp.status_code == status.HTTP_404_NOT_FOUND


# ── terminate ──────────────────────────────────────────────────────────────────


def test_terminate(client: APIClient, landlord: User) -> None:
    lease = LeaseFactory(landlord=landlord, status=LeaseStatus.ACTIVE)

    resp = client.post(f"{_detail(lease.pk)}/terminate", {}, format="json")

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data["status"] == LeaseStatus.TERMINATED.value
    lease.refresh_from_db()
    assert lease.status == LeaseStatus.TERMINATED.value


def test_terminate_as_ended(client: APIClient, landlord: User) -> None:
    lease = LeaseFactory(landlord=landlord, status=LeaseStatus.ACTIVE)

    resp = client.post(
        f"{_detail(lease.pk)}/terminate",
        {"status": LeaseStatus.ENDED.value},
        format="json",
    )

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data["status"] == LeaseStatus.ENDED.value


def test_terminate_writes_audit(client: APIClient, landlord: User) -> None:
    lease = LeaseFactory(landlord=landlord, status=LeaseStatus.ACTIVE)

    client.post(f"{_detail(lease.pk)}/terminate", {}, format="json")

    entry = AuditEntry.objects.get(action="lease.terminate")
    assert entry.actor_id == landlord.pk
    assert entry.before == {"status": LeaseStatus.ACTIVE.value}
    assert entry.after == {"status": LeaseStatus.TERMINATED.value}


def test_terminate_draft_rejected(client: APIClient, landlord: User) -> None:
    lease = LeaseFactory(landlord=landlord, status=LeaseStatus.DRAFT)

    resp = client.post(f"{_detail(lease.pk)}/terminate", {}, format="json")

    assert resp.status_code == status.HTTP_400_BAD_REQUEST


def test_terminate_foreign_lease_404(client: APIClient) -> None:
    other = LeaseFactory(status=LeaseStatus.ACTIVE)

    resp = client.post(f"{_detail(other.pk)}/terminate", {}, format="json")

    assert resp.status_code == status.HTTP_404_NOT_FOUND
