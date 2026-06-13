"""Tests for the ``Building`` and ``Unit`` models (T-001 test plan §12)."""

from __future__ import annotations

from decimal import Decimal

import pytest
from django.db import models

from khatir.properties.enums import Area, UnitStatus, UnitType
from khatir.properties.models import Building, Unit

from .factories import BuildingFactory, UnitFactory

pytestmark = pytest.mark.django_db


# --- Building ---------------------------------------------------------------


def test_building_create() -> None:
    building: Building = BuildingFactory(name="Karim Manzil", area=Area.MIRPUR)  # type: ignore[assignment]
    assert building.pk is not None
    assert building.name == "Karim Manzil"
    assert building.area == Area.MIRPUR
    assert building.owner_id is not None
    assert str(building) == "Karim Manzil"


def test_building_lat_lng_optional() -> None:
    building: Building = BuildingFactory()  # type: ignore[assignment]
    assert building.lat is None
    assert building.lng is None


def test_building_owner_is_protected() -> None:
    """Deleting an owner with buildings must raise, not cascade."""
    from django.db.models import ProtectedError

    building: Building = BuildingFactory()  # type: ignore[assignment]
    with pytest.raises(ProtectedError):
        building.owner.delete()


def test_building_soft_delete() -> None:
    building: Building = BuildingFactory()  # type: ignore[assignment]
    pk = building.pk
    building.delete()
    assert building.is_deleted is True
    assert Building.objects.filter(pk=pk).count() == 0
    assert Building.all_objects.filter(pk=pk).count() == 1


# --- Unit -------------------------------------------------------------------


def test_unit_create() -> None:
    unit: Unit = UnitFactory(label="4B")  # type: ignore[assignment]
    assert unit.pk is not None
    assert unit.label == "4B"
    assert unit.building_id is not None
    assert str(unit) == f"{unit.building.name} · 4B"


def test_unit_rent_is_decimal() -> None:
    unit: Unit = UnitFactory(rent=Decimal("12345.67"))  # type: ignore[assignment]
    unit.refresh_from_db()
    assert isinstance(unit.rent, Decimal)
    assert unit.rent == Decimal("12345.67")


def test_unit_status_enum() -> None:
    unit: Unit = UnitFactory(status=UnitStatus.OCCUPIED)  # type: ignore[assignment]
    assert unit.status == UnitStatus.OCCUPIED
    assert unit.status in UnitStatus.values


def test_unit_type_enum() -> None:
    unit: Unit = UnitFactory(type=UnitType.COMMERCIAL)  # type: ignore[assignment]
    assert unit.type in UnitType.values


def test_unit_amenities_defaults_to_list() -> None:
    unit: Unit = UnitFactory(amenities=["lift", "parking"])  # type: ignore[assignment]
    unit.refresh_from_db()
    assert unit.amenities == ["lift", "parking"]


def test_unit_available_from_nullable() -> None:
    unit: Unit = UnitFactory()  # type: ignore[assignment]
    assert unit.available_from is None


def test_unit_cascades_on_building_delete() -> None:
    """Hard-deleting a building removes its units (CASCADE)."""
    unit: Unit = UnitFactory()  # type: ignore[assignment]
    building = unit.building
    unit_pk = unit.pk
    building.hard_delete()
    assert Unit.all_objects.filter(pk=unit_pk).count() == 0


# --- Enums match enums.md ---------------------------------------------------


def test_area_values_match_spec() -> None:
    assert set(Area.values) == {
        "uttara",
        "mirpur",
        "mohammadpur",
        "dhanmondi",
        "banasree",
        "gulshan",
        "banani",
        "bashundhara",
        "old_dhaka",
        "other",
    }


def test_unit_type_values_match_spec() -> None:
    assert set(UnitType.values) == {
        "apartment",
        "room",
        "commercial",
        "garage",
        "other",
    }


def test_unit_status_values_match_spec() -> None:
    assert set(UnitStatus.values) == {"occupied", "vacant", "maintenance"}


# --- Indexes ----------------------------------------------------------------


def test_indexes_present() -> None:
    building_fields = {tuple(idx.fields) for idx in Building._meta.indexes}
    assert ("owner",) in building_fields

    unit_fields = {tuple(idx.fields) for idx in Unit._meta.indexes}
    assert ("building", "status") in unit_fields


def test_owner_fk_is_protect() -> None:
    field = Building._meta.get_field("owner")
    assert isinstance(field, models.ForeignKey)
    assert field.remote_field.on_delete is models.PROTECT


def test_building_fk_is_cascade() -> None:
    field = Unit._meta.get_field("building")
    assert isinstance(field, models.ForeignKey)
    assert field.remote_field.on_delete is models.CASCADE
