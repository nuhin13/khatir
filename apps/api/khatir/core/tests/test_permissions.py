"""Tests for the reusable role permission classes (T-002).

Role gating is read off ``request.user.role`` (DB truth), so these tests build
real DRF requests with real ``User`` rows and exercise each class allow/deny.
"""

import itertools
from typing import Any

import pytest
from django.contrib.auth.models import AnonymousUser
from rest_framework.request import Request
from rest_framework.test import APIRequestFactory
from rest_framework.views import APIView

from khatir.accounts.models import User
from khatir.core.enums import Role
from khatir.core.permissions import (
    HasRole,
    IsAdminRole,
    IsAuthenticated,
    IsLandlord,
    IsLandlordOrManager,
    IsManager,
    IsTenant,
    RoleBasedPermission,
)

pytestmark = pytest.mark.django_db

ALL_ROLES = [Role.LANDLORD, Role.MANAGER, Role.TENANT, Role.CARETAKER, Role.ADMIN]

_factory = APIRequestFactory()
_view = APIView()
_phone_seq = itertools.count(1)


def _request_for(user: object) -> Request:
    request = Request(_factory.get("/"))
    request.user = user  # type: ignore[assignment]
    return request


def _allows(perm: Any, user: object) -> bool:
    # ``perm`` is any DRF permission instance, including the ``OperandHolder``
    # objects produced by ``&`` / ``|`` composition.
    return bool(perm.has_permission(_request_for(user), _view))


def _user(role: str) -> User:
    return User.objects.create_user(phone=f"+8801700{next(_phone_seq):06d}", role=role)


# (permission class, set of roles it must allow)
ROLE_CASES = [
    (IsLandlord, {Role.LANDLORD}),
    (IsManager, {Role.MANAGER}),
    (IsTenant, {Role.TENANT}),
    (IsAdminRole, {Role.ADMIN}),
    (IsLandlordOrManager, {Role.LANDLORD, Role.MANAGER}),
]


@pytest.mark.parametrize("perm_class,allowed_roles", ROLE_CASES)
@pytest.mark.parametrize("role", ALL_ROLES)
def test_role_permission_allows_only_its_roles(
    perm_class: type[RoleBasedPermission], allowed_roles: set[str], role: str
) -> None:
    perm = perm_class()
    assert _allows(perm, _user(role)) is (role in allowed_roles)


@pytest.mark.parametrize("perm_class,_allowed", ROLE_CASES)
def test_role_permission_denies_anonymous(
    perm_class: type[RoleBasedPermission], _allowed: set[str]
) -> None:
    perm = perm_class()
    assert _allows(perm, AnonymousUser()) is False


@pytest.mark.parametrize("role", ALL_ROLES)
def test_has_role_factory_single_role(role: str) -> None:
    perm = HasRole(Role.LANDLORD)()
    assert _allows(perm, _user(role)) is (role == Role.LANDLORD)


@pytest.mark.parametrize("role", ALL_ROLES)
def test_has_role_factory_multiple_roles(role: str) -> None:
    perm = HasRole(Role.LANDLORD, Role.MANAGER)()
    assert _allows(perm, _user(role)) is (role in {Role.LANDLORD, Role.MANAGER})


def test_has_role_factory_matches_named_or_class() -> None:
    factory = HasRole(Role.LANDLORD, Role.MANAGER)()
    named = IsLandlordOrManager()
    for role in ALL_ROLES:
        user = _user(role)
        assert _allows(factory, user) == _allows(named, user)


def test_has_role_factory_denies_anonymous() -> None:
    perm = HasRole(Role.LANDLORD)()
    assert _allows(perm, AnonymousUser()) is False


def test_has_role_factory_distinct_class_name() -> None:
    perm_class = HasRole(Role.LANDLORD, Role.MANAGER)
    assert "landlord" in perm_class.__name__
    assert "manager" in perm_class.__name__


@pytest.mark.parametrize("role", ALL_ROLES)
def test_empty_required_roles_allows_any_authenticated(role: str) -> None:
    perm = RoleBasedPermission()
    assert _allows(perm, _user(role)) is True


def test_is_authenticated_allows_authenticated_denies_anonymous() -> None:
    perm = IsAuthenticated()
    assert _allows(perm, _user(Role.TENANT)) is True
    assert _allows(perm, AnonymousUser()) is False


def test_role_classes_compose_with_and_or() -> None:
    """DRF operator composition (``&`` / ``|``) yields usable permissions."""
    or_perm = (IsLandlord | IsManager)()
    and_perm = (IsLandlord & IsAuthenticated)()

    assert _allows(or_perm, _user(Role.LANDLORD)) is True
    assert _allows(or_perm, _user(Role.MANAGER)) is True
    assert _allows(or_perm, _user(Role.TENANT)) is False

    assert _allows(and_perm, _user(Role.LANDLORD)) is True
    assert _allows(and_perm, _user(Role.TENANT)) is False
