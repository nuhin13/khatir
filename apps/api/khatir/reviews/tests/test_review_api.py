"""API tests for the review submit + view endpoints (T-002 §12).

Exercises the two — and only two — review routes through DRF's ``APIClient``:

- ``POST /api/v1/leases/{id}/reviews`` — lease-party only, one per party per
  lease, kill-switch gated, audited.
- ``GET  /api/v1/me/reviews`` — reviews about the viewer, reveal-filtered
  (double-blind: a counterpart review stays masked until the viewer submits).

Plus the structural guarantee that NO public/search/aggregate route exists.
"""

from __future__ import annotations

import pytest
from rest_framework import status
from rest_framework.test import APIClient

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.core.models import AuditEntry
from khatir.featureflags.enums import FlagScope
from khatir.featureflags.models import FeatureFlag
from khatir.leases.models import Lease
from khatir.leases.tests.factories import LeaseFactory
from khatir.reviews.models import Review
from khatir.tenants.tests.factories import TenantFactory

pytestmark = pytest.mark.django_db


@pytest.fixture
def landlord() -> User:
    user: User = UserFactory(  # type: ignore[assignment]
        phone="+8801711111111", name="Landlord", role=Role.LANDLORD
    )
    return user


@pytest.fixture
def tenant_user() -> User:
    user: User = UserFactory(  # type: ignore[assignment]
        phone="+8801722222222", name="Tenant", role=Role.TENANT
    )
    return user


@pytest.fixture
def lease(landlord: User, tenant_user: User) -> Lease:
    tenant = TenantFactory(linked_user=tenant_user)
    return LeaseFactory(landlord=landlord, tenant=tenant)  # type: ignore[no-any-return]


def _submit_url(lease_id: object) -> str:
    return f"/api/v1/leases/{lease_id}/reviews"


MY_REVIEWS_URL = "/api/v1/me/reviews"


def _enable_kill_switch(enabled: bool) -> None:
    FeatureFlag.objects.update_or_create(
        key="reviews_feature",
        defaults={"scope": FlagScope.GLOBAL, "enabled": enabled},
    )


def _client(user: User) -> APIClient:
    api = APIClient()
    api.force_authenticate(user=user)
    return api


def test_submit_party_only(landlord: User, lease: Lease) -> None:
    """A lease party can submit; the review is stored about the counterpart."""
    resp = _client(landlord).post(
        _submit_url(lease.pk), {"rating": 5, "comment": "Reliable."}, format="json"
    )
    assert resp.status_code == status.HTTP_201_CREATED
    review = Review.objects.get(lease=lease, reviewer=landlord)
    assert review.reviewee_id == lease.tenant.linked_user_id
    assert review.rating == 5


def test_submit_writes_audit(landlord: User, lease: Lease) -> None:
    _client(landlord).post(_submit_url(lease.pk), {"rating": 4}, format="json")
    assert AuditEntry.objects.filter(action="review.submit").exists()


def test_non_party_403(lease: Lease) -> None:
    """A user who is neither landlord nor tenant of the lease is forbidden."""
    outsider: User = UserFactory(  # type: ignore[assignment]
        phone="+8801733333333", role=Role.LANDLORD
    )
    resp = _client(outsider).post(
        _submit_url(lease.pk), {"rating": 3}, format="json"
    )
    assert resp.status_code == status.HTTP_403_FORBIDDEN
    assert not Review.objects.filter(reviewer=outsider).exists()


def test_one_review_per_party_per_lease(landlord: User, lease: Lease) -> None:
    client = _client(landlord)
    first = client.post(_submit_url(lease.pk), {"rating": 5}, format="json")
    assert first.status_code == status.HTTP_201_CREATED
    second = client.post(_submit_url(lease.pk), {"rating": 1}, format="json")
    assert second.status_code == status.HTTP_409_CONFLICT
    assert Review.objects.filter(lease=lease, reviewer=landlord).count() == 1


def test_killswitch_off(landlord: User, lease: Lease) -> None:
    """With ``reviews_feature`` flipped off the whole feature is 403."""
    _enable_kill_switch(False)
    submit = _client(landlord).post(
        _submit_url(lease.pk), {"rating": 5}, format="json"
    )
    assert submit.status_code == status.HTTP_403_FORBIDDEN
    view = _client(landlord).get(MY_REVIEWS_URL)
    assert view.status_code == status.HTTP_403_FORBIDDEN


def test_killswitch_on_explicitly(landlord: User, lease: Lease) -> None:
    _enable_kill_switch(True)
    resp = _client(landlord).post(
        _submit_url(lease.pk), {"rating": 5}, format="json"
    )
    assert resp.status_code == status.HTTP_201_CREATED


def test_me_reviews_double_blind(
    landlord: User, tenant_user: User, lease: Lease
) -> None:
    """Counterpart review stays masked until the viewer submits their own."""
    # Landlord submits a review about the tenant.
    _client(landlord).post(_submit_url(lease.pk), {"rating": 2, "comment": "x"}, format="json")

    # Tenant has NOT yet submitted — the review about them is pending/masked.
    before = _client(tenant_user).get(MY_REVIEWS_URL)
    assert before.status_code == status.HTTP_200_OK
    assert before.data["revealed"] == []
    assert len(before.data["pending"]) == 1
    pending = before.data["pending"][0]
    assert pending["revealed"] is False
    assert "rating" not in pending and "comment" not in pending

    # Tenant submits their counterpart review → double-blind condition met.
    _client(tenant_user).post(_submit_url(lease.pk), {"rating": 4}, format="json")
    after = _client(tenant_user).get(MY_REVIEWS_URL)
    assert after.data["pending"] == []
    assert len(after.data["revealed"]) == 1
    assert after.data["revealed"][0]["rating"] == 2
    assert after.data["revealed"][0]["comment"] == "x"


def test_me_reviews_scoped_to_self(
    landlord: User, tenant_user: User, lease: Lease
) -> None:
    """/me/reviews never returns reviews about anyone but the caller."""
    _client(tenant_user).post(_submit_url(lease.pk), {"rating": 5}, format="json")
    # The review is ABOUT the landlord; the tenant must not see it as theirs.
    resp = _client(tenant_user).get(MY_REVIEWS_URL)
    assert resp.data["revealed"] == []
    assert resp.data["pending"] == []


def test_no_public_or_search_route(landlord: User) -> None:
    """There is deliberately no collection/search/per-user reviews route."""
    client = _client(landlord)
    assert client.get("/api/v1/reviews").status_code == status.HTTP_404_NOT_FOUND
    assert (
        client.get(f"/api/v1/users/{landlord.pk}/reviews").status_code
        == status.HTTP_404_NOT_FOUND
    )


def test_submit_requires_auth(lease: Lease) -> None:
    resp = APIClient().post(_submit_url(lease.pk), {"rating": 5}, format="json")
    assert resp.status_code in (
        status.HTTP_401_UNAUTHORIZED,
        status.HTTP_403_FORBIDDEN,
    )
