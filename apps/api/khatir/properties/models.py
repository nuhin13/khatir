"""Properties domain models — Domain 2 of ``06_database_schema.md``.

A ``Building`` is a physical property owned by a landlord; it contains one or
more ``Unit`` rentables. Both are user-facing records, so they inherit
``SoftDeleteModel`` (timestamps + soft delete). The owner FK is ``PROTECT`` (you
cannot delete a landlord while buildings exist); the building FK is ``CASCADE``
(deleting a building removes its units). Money is ``Decimal(12,2)`` in Taka.

The ``for_user`` scoping rule lives in T-002 — it is intentionally absent here.
"""

from __future__ import annotations

from decimal import Decimal

from django.conf import settings
from django.db import models

from khatir.core.models import AllObjectsManager, SoftDeleteModel

from .enums import Area, UnitStatus, UnitType
from .managers import BuildingManager, UnitManager


class Building(SoftDeleteModel):
    """A physical property owned by a landlord."""

    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="buildings",
        help_text="The landlord who owns this building.",
    )
    name = models.CharField(max_length=120, help_text='e.g. "Karim Manzil".')
    area = models.CharField(
        max_length=16,
        choices=Area.choices,
        help_text="Dhaka zone the building sits in.",
    )
    address = models.TextField(help_text="Full address — printed on the DMP form.")
    lat = models.DecimalField(
        max_digits=12,
        decimal_places=9,
        null=True,
        blank=True,
        default=None,
        help_text="Optional map-pin latitude.",
    )
    lng = models.DecimalField(
        max_digits=12,
        decimal_places=9,
        null=True,
        blank=True,
        default=None,
        help_text="Optional map-pin longitude.",
    )

    objects = BuildingManager()  # type: ignore[misc]
    all_objects = AllObjectsManager()  # type: ignore[misc]

    class Meta:
        ordering = ("-created_at",)
        indexes = [models.Index(fields=["owner"])]

    def __str__(self) -> str:
        return self.name


class Unit(SoftDeleteModel):
    """One rentable flat/room inside a building."""

    building = models.ForeignKey(
        Building,
        on_delete=models.CASCADE,
        related_name="units",
        help_text="Parent building; deleting it removes its units.",
    )
    label = models.CharField(max_length=40, help_text='e.g. "4B".')
    type = models.CharField(
        max_length=16,
        choices=UnitType.choices,
        default=UnitType.APARTMENT,
        help_text="apartment / room / commercial / garage / other.",
    )
    rent = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal("0.00"),
        help_text="Monthly rent in Taka.",
    )
    amenities = models.JSONField(
        default=list,
        blank=True,
        help_text="List of amenities.",
    )
    status = models.CharField(
        max_length=16,
        choices=UnitStatus.choices,
        default=UnitStatus.VACANT,
        help_text="occupied / vacant / maintenance.",
    )
    available_from = models.DateField(
        null=True,
        blank=True,
        default=None,
        help_text="When the unit becomes available.",
    )

    objects = UnitManager()  # type: ignore[misc]
    all_objects = AllObjectsManager()  # type: ignore[misc]

    class Meta:
        ordering = ("building", "label")
        indexes = [models.Index(fields=["building", "status"])]

    def __str__(self) -> str:
        return f"{self.building.name} · {self.label}"
