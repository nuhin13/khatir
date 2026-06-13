"""Row-level isolation tests (T-002 test plan §12).

Covers ``Building/Unit.objects.for_user`` and the object-level permissions
``IsOwnerOfBuilding`` / ``IsOwnerOfUnit``. The manager→owner link table
(``ManagerOwnerLink``) is only fully populated in EPIC-22, so the manager cases
inject the documented ``managed_owner_ids()`` helper onto the user instance.
"""

from __future__ import annotations

from typing import Any

import pytest

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.properties.models import Building, Unit
from khatir.properties.permissions import IsOwnerOfBuilding, IsOwnerOfUnit

from .factories import BuildingFactory, UnitFactory

pytestmark = pytest.mark.django_db


def _request(user: Any) -> Any:
    """Minimal stand-in for a DRF request carrying ``user``."""
    return type("Req", (), {"user": user})()


# --- Building.for_user -------------------------------------------------------


def test_for_user_landlord_sees_own_only() -> None:
    landlord: User = UserFactory(role=Role.LANDLORD)  # type: ignore[assignment]
    mine: Building = BuildingFactory(owner=landlord)  # type: ignore[assignment]
    BuildingFactory()  # someone else's building

    qs = Building.objects.for_user(landlord)

    assert list(qs) == [mine]


def test_for_user_other_landlord_gets_none() -> None:
    landlord: User = UserFactory(role=Role.LANDLORD)  # type: ignore[assignment]
    other: User = UserFactory(role=Role.LANDLORD)  # type: ignore[assignment]
    BuildingFactory(owner=other)

    qs = Building.objects.for_user(landlord)

    assert qs.count() == 0


def test_for_user_manager_sees_linked_owners() -> None:
    owner_a: User = UserFactory(role=Role.LANDLORD)  # type: ignore[assignment]
    owner_b: User = UserFactory(role=Role.LANDLORD)  # type: ignore[assignment]
    unlinked: User = UserFactory(role=Role.LANDLORD)  # type: ignore[assignment]
    b_a: Building = BuildingFactory(owner=owner_a)  # type: ignore[assignment]
    b_b: Building = BuildingFactory(owner=owner_b)  # type: ignore[assignment]
    BuildingFactory(owner=unlinked)

    manager: User = UserFactory(role=Role.MANAGER)  # type: ignore[assignment]
    manager.managed_owner_ids = lambda: [owner_a.pk, owner_b.pk]  # type: ignore[attr-defined]

    qs = Building.objects.for_user(manager)

    assert set(qs) == {b_a, b_b}


def test_for_user_manager_without_links_sees_none() -> None:
    UserFactory(role=Role.LANDLORD)
    BuildingFactory()
    manager: User = UserFactory(role=Role.MANAGER)  # type: ignore[assignment]

    assert Building.objects.for_user(manager).count() == 0


def test_for_user_tenant_gets_none() -> None:
    tenant: User = UserFactory(role=Role.TENANT)  # type: ignore[assignment]
    BuildingFactory()

    assert Building.objects.for_user(tenant).count() == 0


def test_for_user_anonymous_gets_none() -> None:
    BuildingFactory()

    class Anon:
        is_authenticated = False
        role = None

    assert Building.objects.for_user(Anon()).count() == 0


def test_for_user_excludes_soft_deleted() -> None:
    landlord: User = UserFactory(role=Role.LANDLORD)  # type: ignore[assignment]
    alive: Building = BuildingFactory(owner=landlord)  # type: ignore[assignment]
    dead: Building = BuildingFactory(owner=landlord)  # type: ignore[assignment]
    dead.delete()  # soft delete

    qs = Building.objects.for_user(landlord)

    assert list(qs) == [alive]


# --- Unit.for_user (scopes via building) ------------------------------------


def test_unit_for_user_landlord_sees_own_only() -> None:
    landlord: User = UserFactory(role=Role.LANDLORD)  # type: ignore[assignment]
    my_building: Building = BuildingFactory(owner=landlord)  # type: ignore[assignment]
    mine: Unit = UnitFactory(building=my_building)  # type: ignore[assignment]
    UnitFactory()  # unit in someone else's building

    qs = Unit.objects.for_user(landlord)

    assert list(qs) == [mine]


def test_unit_for_user_manager_sees_linked() -> None:
    owner: User = UserFactory(role=Role.LANDLORD)  # type: ignore[assignment]
    building: Building = BuildingFactory(owner=owner)  # type: ignore[assignment]
    unit: Unit = UnitFactory(building=building)  # type: ignore[assignment]
    UnitFactory()  # unrelated

    manager: User = UserFactory(role=Role.MANAGER)  # type: ignore[assignment]
    manager.managed_owner_ids = lambda: [owner.pk]  # type: ignore[attr-defined]

    assert list(Unit.objects.for_user(manager)) == [unit]


def test_unit_for_user_tenant_gets_none() -> None:
    tenant: User = UserFactory(role=Role.TENANT)  # type: ignore[assignment]
    UnitFactory()

    assert Unit.objects.for_user(tenant).count() == 0


# --- Object-level permissions -----------------------------------------------


def test_is_owner_of_building_allows_owner_denies_others() -> None:
    landlord: User = UserFactory(role=Role.LANDLORD)  # type: ignore[assignment]
    other: User = UserFactory(role=Role.LANDLORD)  # type: ignore[assignment]
    building: Building = BuildingFactory(owner=landlord)  # type: ignore[assignment]
    perm = IsOwnerOfBuilding()

    assert perm.has_object_permission(_request(landlord), None, building) is True
    assert perm.has_object_permission(_request(other), None, building) is False


def test_is_owner_of_building_allows_linked_manager() -> None:
    owner: User = UserFactory(role=Role.LANDLORD)  # type: ignore[assignment]
    building: Building = BuildingFactory(owner=owner)  # type: ignore[assignment]
    manager: User = UserFactory(role=Role.MANAGER)  # type: ignore[assignment]
    manager.managed_owner_ids = lambda: [owner.pk]  # type: ignore[attr-defined]
    unlinked_manager: User = UserFactory(role=Role.MANAGER)  # type: ignore[assignment]
    perm = IsOwnerOfBuilding()

    assert perm.has_object_permission(_request(manager), None, building) is True
    assert perm.has_object_permission(_request(unlinked_manager), None, building) is False


def test_is_owner_of_building_denies_tenant() -> None:
    tenant: User = UserFactory(role=Role.TENANT)  # type: ignore[assignment]
    building: Building = BuildingFactory()  # type: ignore[assignment]
    perm = IsOwnerOfBuilding()

    assert perm.has_object_permission(_request(tenant), None, building) is False


def test_is_owner_of_unit_allows_owner_denies_others() -> None:
    landlord: User = UserFactory(role=Role.LANDLORD)  # type: ignore[assignment]
    other: User = UserFactory(role=Role.LANDLORD)  # type: ignore[assignment]
    unit: Unit = UnitFactory(building=BuildingFactory(owner=landlord))  # type: ignore[assignment]
    perm = IsOwnerOfUnit()

    assert perm.has_object_permission(_request(landlord), None, unit) is True
    assert perm.has_object_permission(_request(other), None, unit) is False


def test_is_owner_of_unit_allows_linked_manager() -> None:
    owner: User = UserFactory(role=Role.LANDLORD)  # type: ignore[assignment]
    unit: Unit = UnitFactory(building=BuildingFactory(owner=owner))  # type: ignore[assignment]
    manager: User = UserFactory(role=Role.MANAGER)  # type: ignore[assignment]
    manager.managed_owner_ids = lambda: [owner.pk]  # type: ignore[attr-defined]
    perm = IsOwnerOfUnit()

    assert perm.has_object_permission(_request(manager), None, unit) is True
