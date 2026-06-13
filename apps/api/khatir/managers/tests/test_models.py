"""Tests for ManagerOwnerLink: status lifecycle, consent, scoping."""

from __future__ import annotations

import pytest
from django.db import IntegrityError

from khatir.accounts.enums import Role
from khatir.accounts.tests.factories import UserFactory
from khatir.compliance.enums import ConsentType
from khatir.compliance.tests.factories import ConsentRecordFactory
from khatir.managers.enums import ManagerOwnerLinkStatus
from khatir.managers.models import ManagerOwnerLink

from .factories import ManagerOwnerLinkFactory

pytestmark = pytest.mark.django_db


def test_link_defaults_to_pending_with_empty_scope() -> None:
    link = ManagerOwnerLinkFactory()
    assert link.status == ManagerOwnerLinkStatus.PENDING
    assert link.permissions_scope == []
    assert link.consent_record is None
    assert link.is_active is False


def test_active_link_carries_consent_record_and_scope() -> None:
    owner = UserFactory(role=Role.LANDLORD)
    consent = ConsentRecordFactory(
        user=owner, consent_type=ConsentType.PDPA_DATA_SHARING
    )
    link = ManagerOwnerLinkFactory(
        owner=owner,
        status=ManagerOwnerLinkStatus.ACTIVE,
        consent_record=consent,
        permissions_scope=["view_reports", "collect_rent"],
    )
    assert link.is_active is True
    assert link.consent_record == consent
    assert link.permissions_scope == ["view_reports", "collect_rent"]


def test_unique_manager_owner_pair() -> None:
    link = ManagerOwnerLinkFactory()
    with pytest.raises(IntegrityError):
        ManagerOwnerLink.objects.create(manager=link.manager, owner=link.owner)


def test_active_owner_ids_for_returns_only_active_linked_owners() -> None:
    manager = UserFactory(role=Role.MANAGER)
    active_owner = UserFactory(role=Role.LANDLORD)
    pending_owner = UserFactory(role=Role.LANDLORD)
    revoked_owner = UserFactory(role=Role.LANDLORD)

    ManagerOwnerLinkFactory(
        manager=manager, owner=active_owner, status=ManagerOwnerLinkStatus.ACTIVE
    )
    ManagerOwnerLinkFactory(
        manager=manager, owner=pending_owner, status=ManagerOwnerLinkStatus.PENDING
    )
    ManagerOwnerLinkFactory(
        manager=manager, owner=revoked_owner, status=ManagerOwnerLinkStatus.REVOKED
    )

    owner_ids = ManagerOwnerLink.objects.active_owner_ids_for(manager)
    assert owner_ids == [active_owner.pk]


def test_active_owner_ids_for_excludes_other_managers_links() -> None:
    manager = UserFactory(role=Role.MANAGER)
    other_manager = UserFactory(role=Role.MANAGER)
    my_owner = UserFactory(role=Role.LANDLORD)
    their_owner = UserFactory(role=Role.LANDLORD)

    ManagerOwnerLinkFactory(
        manager=manager, owner=my_owner, status=ManagerOwnerLinkStatus.ACTIVE
    )
    ManagerOwnerLinkFactory(
        manager=other_manager,
        owner=their_owner,
        status=ManagerOwnerLinkStatus.ACTIVE,
    )

    assert ManagerOwnerLink.objects.active_owner_ids_for(manager) == [my_owner.pk]


def test_active_owner_ids_for_unsaved_manager_is_empty() -> None:
    assert ManagerOwnerLink.objects.active_owner_ids_for(object()) == []


def test_for_manager_returns_all_statuses() -> None:
    manager = UserFactory(role=Role.MANAGER)
    ManagerOwnerLinkFactory(manager=manager, status=ManagerOwnerLinkStatus.ACTIVE)
    ManagerOwnerLinkFactory(manager=manager, status=ManagerOwnerLinkStatus.PENDING)
    assert ManagerOwnerLink.objects.for_manager(manager).count() == 2
    assert ManagerOwnerLink.objects.for_manager(manager).active().count() == 1
