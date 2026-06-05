"""API + scoping tests for the per-owner manager report (T-005 §12).

Exercises ``GET /api/v1/manager/owners/{owner_id}/report`` through DRF's
``APIClient`` with a real authenticated manager. Covers the PDF happy path,
active-link scoping (only owners with an **active** link are reachable; pending,
revoked, and other managers' owners resolve to 404), the audit row written on a
successful read, the ``months`` query param, role gating, auth, and the
``b2b_manager_enabled`` feature-flag gate.
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
from khatir.managers.enums import ManagerOwnerLinkStatus

from .factories import ManagerOwnerLinkFactory

pytestmark = pytest.mark.django_db


def _url(owner_id: int) -> str:
    return f"/api/v1/manager/owners/{owner_id}/report"


@pytest.fixture(autouse=True)
def _flag_on() -> None:
    FeatureFlag.objects.create(
        key="b2b_manager_enabled", scope=FlagScope.GLOBAL, enabled=True
    )


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


def _link(manager: User, owner: User, status_: str) -> object:
    return ManagerOwnerLinkFactory(manager=manager, owner=owner, status=status_)


def test_active_link_returns_pdf(client: APIClient, manager: User) -> None:
    """A manager actively linked to an owner gets a PDF report."""
    owner = _owner()
    _link(manager, owner, ManagerOwnerLinkStatus.ACTIVE)

    resp = client.get(_url(owner.pk))

    assert resp.status_code == status.HTTP_200_OK
    assert resp["Content-Type"] == "application/pdf"
    assert resp.content.startswith(b"%PDF-")
    assert f"owner-{owner.pk}-report.pdf" in resp["Content-Disposition"]


def test_report_is_deterministic(client: APIClient, manager: User) -> None:
    """Same owner + window renders byte-identical bytes (reuses EPIC-05)."""
    owner = _owner()
    _link(manager, owner, ManagerOwnerLinkStatus.ACTIVE)

    first = client.get(_url(owner.pk)).content
    second = client.get(_url(owner.pk)).content
    assert first == second


def test_successful_read_is_audited(client: APIClient, manager: User) -> None:
    """A successful access writes one ``manager.owner_report.read`` audit row."""
    owner = _owner()
    link = _link(manager, owner, ManagerOwnerLinkStatus.ACTIVE)

    client.get(_url(owner.pk))

    entry = AuditEntry.objects.get(action="manager.owner_report.read")
    assert entry.actor_id == manager.pk
    assert entry.target_type == "managers.managerownerlink"
    assert entry.target_id == str(link.pk)
    assert entry.after["owner_id"] == owner.pk


def test_pending_link_not_reachable(client: APIClient, manager: User) -> None:
    """A pending (not-yet-consented) link resolves to 404, no audit row."""
    owner = _owner()
    _link(manager, owner, ManagerOwnerLinkStatus.PENDING)

    resp = client.get(_url(owner.pk))

    assert resp.status_code == status.HTTP_404_NOT_FOUND
    assert not AuditEntry.objects.filter(
        action="manager.owner_report.read"
    ).exists()


def test_revoked_link_not_reachable(client: APIClient, manager: User) -> None:
    """A revoked link resolves to 404."""
    owner = _owner()
    _link(manager, owner, ManagerOwnerLinkStatus.REVOKED)

    assert client.get(_url(owner.pk)).status_code == status.HTTP_404_NOT_FOUND


def test_other_managers_owner_not_reachable(
    client: APIClient, manager: User
) -> None:
    """Another manager's active link never grants access (404)."""
    other_manager = UserFactory(role=Role.MANAGER)
    other_owner = _owner()
    _link(other_manager, other_owner, ManagerOwnerLinkStatus.ACTIVE)

    assert (
        client.get(_url(other_owner.pk)).status_code
        == status.HTTP_404_NOT_FOUND
    )


def test_unknown_owner_404(client: APIClient) -> None:
    """An owner the manager has no link to at all resolves to 404."""
    assert client.get(_url(999999)).status_code == status.HTTP_404_NOT_FOUND


def test_months_param_accepted(client: APIClient, manager: User) -> None:
    """The ``months`` window param is accepted and still yields a PDF."""
    owner = _owner()
    _link(manager, owner, ManagerOwnerLinkStatus.ACTIVE)

    resp = client.get(_url(owner.pk), {"months": 3})

    assert resp.status_code == status.HTTP_200_OK
    assert resp["Content-Type"] == "application/pdf"


def test_landlord_role_forbidden() -> None:
    """A landlord cannot read the manager report endpoint."""
    owner = _owner()
    api = APIClient()
    api.force_authenticate(user=UserFactory(role=Role.LANDLORD))
    assert api.get(_url(owner.pk)).status_code == status.HTTP_403_FORBIDDEN


def test_requires_auth() -> None:
    owner = _owner()
    resp = APIClient().get(_url(owner.pk))
    assert resp.status_code in (
        status.HTTP_401_UNAUTHORIZED,
        status.HTTP_403_FORBIDDEN,
    )


def test_flag_off_blocks_endpoint(client: APIClient, manager: User) -> None:
    owner = _owner()
    _link(manager, owner, ManagerOwnerLinkStatus.ACTIVE)
    FeatureFlag.objects.filter(key="b2b_manager_enabled").update(enabled=False)
    assert client.get(_url(owner.pk)).status_code == status.HTTP_403_FORBIDDEN
