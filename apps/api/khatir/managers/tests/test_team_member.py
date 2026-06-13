"""Tests for ManagerTeamMember: role, scope, status, and scoping helpers."""

from __future__ import annotations

import pytest
from django.db import IntegrityError

from khatir.accounts.enums import Role
from khatir.accounts.tests.factories import UserFactory
from khatir.managers.enums import (
    ManagerTeamMemberRole,
    ManagerTeamMemberStatus,
)
from khatir.managers.models import ManagerTeamMember

from .factories import ManagerTeamMemberFactory

pytestmark = pytest.mark.django_db


def test_seat_defaults_to_active_staff_with_empty_scope() -> None:
    member = ManagerTeamMemberFactory()
    assert member.role == ManagerTeamMemberRole.STAFF
    assert member.status == ManagerTeamMemberStatus.ACTIVE
    assert member.permissions_scope == []
    assert member.is_active is True


def test_sub_manager_carries_scope() -> None:
    member = ManagerTeamMemberFactory(
        role=ManagerTeamMemberRole.SUB_MANAGER,
        permissions_scope=["view_reports", "collect_rent"],
    )
    assert member.role == ManagerTeamMemberRole.SUB_MANAGER
    assert member.permissions_scope == ["view_reports", "collect_rent"]


def test_unique_manager_member_pair() -> None:
    seat = ManagerTeamMemberFactory()
    with pytest.raises(IntegrityError):
        ManagerTeamMember.objects.create(
            manager=seat.manager, member=seat.member
        )


def test_staff_permission_is_scope_gated() -> None:
    staff = ManagerTeamMemberFactory(
        role=ManagerTeamMemberRole.STAFF,
        permissions_scope=["view_reports"],
    )
    assert staff.has_permission("view_reports") is True
    assert staff.has_permission("collect_rent") is False


def test_sub_manager_has_all_permissions() -> None:
    sub = ManagerTeamMemberFactory(
        role=ManagerTeamMemberRole.SUB_MANAGER,
        permissions_scope=[],
    )
    assert sub.has_permission("collect_rent") is True
    assert sub.has_permission("anything") is True


def test_revoked_seat_grants_no_permissions() -> None:
    revoked = ManagerTeamMemberFactory(
        role=ManagerTeamMemberRole.SUB_MANAGER,
        status=ManagerTeamMemberStatus.REVOKED,
        permissions_scope=["view_reports"],
    )
    assert revoked.is_active is False
    assert revoked.has_permission("view_reports") is False


def test_active_excludes_revoked_seats() -> None:
    manager = UserFactory(role=Role.MANAGER)
    ManagerTeamMemberFactory(
        manager=manager, status=ManagerTeamMemberStatus.ACTIVE
    )
    ManagerTeamMemberFactory(
        manager=manager, status=ManagerTeamMemberStatus.REVOKED
    )
    assert ManagerTeamMember.objects.for_manager(manager).count() == 2
    assert ManagerTeamMember.objects.for_manager(manager).active().count() == 1


def test_for_manager_excludes_other_managers_seats() -> None:
    manager = UserFactory(role=Role.MANAGER)
    other_manager = UserFactory(role=Role.MANAGER)
    ManagerTeamMemberFactory(manager=manager)
    ManagerTeamMemberFactory(manager=other_manager)

    seats = ManagerTeamMember.objects.for_manager(manager)
    assert seats.count() == 1
    assert seats.first().manager_id == manager.pk


def test_for_manager_unsaved_manager_is_empty() -> None:
    assert list(ManagerTeamMember.objects.for_manager(object())) == []
