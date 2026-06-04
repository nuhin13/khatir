"""API tests for the rent-request create + queue endpoints (T-003 §12).

Exercises ``/api/v1/rent-requests`` through DRF's ``APIClient`` with a real
authenticated landlord. Covers create-from-schedule (amount/period derived,
schedule marked ``requested``, token minted), manual one-off create, the queue
list + status filter, the audit write, and — critically — cross-user **404**
(other landlords' requests are invisible, never 403).
"""

from __future__ import annotations

from decimal import Decimal

import pytest
from rest_framework import status
from rest_framework.test import APIClient

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.core.models import AuditEntry
from khatir.leases.enums import RentScheduleStatus
from khatir.leases.tests.factories import LeaseFactory, RentScheduleFactory
from khatir.rent.enums import RentRequestStatus
from khatir.rent.models import RentRequest
from khatir.rent.tokens import resolve_token

from .factories import RentRequestFactory

pytestmark = pytest.mark.django_db

URL = "/api/v1/rent-requests"


def _detail(pk: object) -> str:
    return f"{URL}/{pk}"


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


# ── create from schedule ──────────────────────────────────────────────────────


def test_create_from_schedule(client: APIClient, landlord: User) -> None:
    lease = LeaseFactory(landlord=landlord, rent=Decimal("18000.00"))
    schedule = RentScheduleFactory(
        lease=lease, period="2026-03", amount=Decimal("18000.00")
    )

    resp = client.post(URL, {"rent_schedule": schedule.pk}, format="json")

    assert resp.status_code == status.HTTP_201_CREATED
    # Amount/period derived from the schedule, not the (absent) body.
    assert resp.data["amount"] == "18000.00"
    assert resp.data["period"] == "2026-03"
    assert resp.data["rent_schedule_id"] == str(schedule.pk)
    assert resp.data["lease_id"] == str(lease.pk)
    assert resp.data["status"] == RentRequestStatus.SENT.value
    # A single-purpose signed token was minted and persisted.
    req = RentRequest.objects.get(pk=resp.data["id"])
    assert req.link_token
    assert resolve_token(req.link_token).pk == req.pk
    # The schedule month is now marked requested so it is not re-asked.
    schedule.refresh_from_db()
    assert schedule.status == RentScheduleStatus.REQUESTED


def test_create_manual_one_off(client: APIClient, landlord: User) -> None:
    lease = LeaseFactory(landlord=landlord)

    resp = client.post(
        URL,
        {"lease": lease.pk, "amount": "12500.00", "period": "2026-04"},
        format="json",
    )

    assert resp.status_code == status.HTTP_201_CREATED
    assert resp.data["rent_schedule_id"] is None
    assert resp.data["amount"] == "12500.00"
    assert resp.data["period"] == "2026-04"
    req = RentRequest.objects.get(pk=resp.data["id"])
    assert req.rent_schedule_id is None
    assert req.link_token


def test_create_requires_schedule_or_lease(client: APIClient) -> None:
    resp = client.post(URL, {"amount": "1000.00", "period": "2026-04"}, format="json")
    assert resp.status_code == status.HTTP_400_BAD_REQUEST


def test_create_manual_requires_amount_and_period(
    client: APIClient, landlord: User
) -> None:
    lease = LeaseFactory(landlord=landlord)
    resp = client.post(URL, {"lease": lease.pk}, format="json")
    assert resp.status_code == status.HTTP_400_BAD_REQUEST


def test_create_writes_audit(client: APIClient, landlord: User) -> None:
    lease = LeaseFactory(landlord=landlord)
    resp = client.post(
        URL,
        {"lease": lease.pk, "amount": "9000.00", "period": "2026-05"},
        format="json",
    )
    assert resp.status_code == status.HTTP_201_CREATED
    assert AuditEntry.objects.filter(
        action="rent.request.create", target_id=str(resp.data["id"])
    ).exists()


def test_create_foreign_schedule_is_404(client: APIClient) -> None:
    other_lease = LeaseFactory(landlord=UserFactory(role=Role.LANDLORD))
    schedule = RentScheduleFactory(lease=other_lease)

    resp = client.post(URL, {"rent_schedule": schedule.pk}, format="json")

    assert resp.status_code == status.HTTP_404_NOT_FOUND
    # The foreign schedule was NOT marked requested.
    schedule.refresh_from_db()
    assert schedule.status == RentScheduleStatus.PENDING


def test_create_foreign_lease_is_404(client: APIClient) -> None:
    other_lease = LeaseFactory(landlord=UserFactory(role=Role.LANDLORD))
    resp = client.post(
        URL,
        {"lease": other_lease.pk, "amount": "9000.00", "period": "2026-05"},
        format="json",
    )
    assert resp.status_code == status.HTTP_404_NOT_FOUND


# ── queue list + detail ────────────────────────────────────────────────────────


def test_queue_lists_own_requests(client: APIClient, landlord: User) -> None:
    lease = LeaseFactory(landlord=landlord)
    RentRequestFactory(lease=lease, link_token="tok_a", status=RentRequestStatus.SENT)
    RentRequestFactory(
        lease=lease, link_token="tok_b", status=RentRequestStatus.VERIFIED
    )

    resp = client.get(URL)

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data["pagination"]["count"] == 2


def test_queue_status_filter(client: APIClient, landlord: User) -> None:
    lease = LeaseFactory(landlord=landlord)
    RentRequestFactory(lease=lease, link_token="tok_c", status=RentRequestStatus.SENT)
    RentRequestFactory(
        lease=lease, link_token="tok_d", status=RentRequestStatus.VERIFIED
    )

    resp = client.get(URL, {"status": RentRequestStatus.SENT.value})

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data["pagination"]["count"] == 1
    assert resp.data["results"][0]["status"] == RentRequestStatus.SENT.value


def test_detail_own_request(client: APIClient, landlord: User) -> None:
    lease = LeaseFactory(landlord=landlord)
    req = RentRequestFactory(lease=lease, link_token="tok_e")

    resp = client.get(_detail(req.pk))

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data["id"] == str(req.pk)


# ── scoping ────────────────────────────────────────────────────────────────────


def test_queue_excludes_other_landlord(client: APIClient) -> None:
    other = LeaseFactory(landlord=UserFactory(role=Role.LANDLORD))
    RentRequestFactory(lease=other, link_token="tok_other")

    resp = client.get(URL)

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data["pagination"]["count"] == 0


def test_detail_foreign_request_is_404(client: APIClient) -> None:
    other = LeaseFactory(landlord=UserFactory(role=Role.LANDLORD))
    req = RentRequestFactory(lease=other, link_token="tok_foreign")

    resp = client.get(_detail(req.pk))

    assert resp.status_code == status.HTTP_404_NOT_FOUND


def test_anonymous_is_rejected() -> None:
    api = APIClient()
    resp = api.get(URL)
    assert resp.status_code in (status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN)


def test_manager_sees_linked_owner_requests(landlord: User) -> None:
    manager: User = UserFactory(  # type: ignore[assignment]
        phone="+8801799999999", role=Role.MANAGER
    )
    manager.managed_owner_ids = lambda: [landlord.pk]  # type: ignore[attr-defined]
    lease = LeaseFactory(landlord=landlord)
    RentRequestFactory(lease=lease, link_token="tok_mgr")

    api = APIClient()
    api.force_authenticate(user=manager)
    resp = api.get(URL)

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data["pagination"]["count"] == 1


def test_for_user_scopes_queryset(landlord: User) -> None:
    lease = LeaseFactory(landlord=landlord)
    mine = RentRequestFactory(lease=lease, link_token="tok_mine")
    RentRequestFactory(
        lease=LeaseFactory(landlord=UserFactory(role=Role.LANDLORD)),
        link_token="tok_theirs",
    )

    qs = RentRequest.objects.for_user(landlord)

    assert list(qs) == [mine]
