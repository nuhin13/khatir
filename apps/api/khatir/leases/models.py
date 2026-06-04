"""Leases domain models — Domain 4 of ``06_database_schema.md``.

A ``Lease`` ties a unit, a tenant, and a landlord together with the financial
terms (monthly rent + advance/deposit) and the lease period. Both the unit and
tenant FKs are ``PROTECT`` — you cannot delete a unit or tenant while an active
lease references them.

A ``RentSchedule`` holds one row per rent period (month) for a lease. It is
CASCADE-deleted with the lease. The ``period`` field stores the month as a
``YYYY-MM`` string (e.g. ``"2026-05"``). Money is ``Decimal(12,2)`` in Taka.

Both models inherit ``SoftDeleteModel`` (user-facing records that should never
be permanently lost). The ``for_user`` scoping rule and schedule auto-generation
are wired in later tasks (T-002+).
"""

from __future__ import annotations

from decimal import Decimal

from django.conf import settings
from django.db import models

from khatir.core.models import AllObjectsManager, SoftDeleteModel, TimeStampedModel

from .enums import LeaseStatus, RentScheduleStatus
from .managers import LeaseManager


class Lease(SoftDeleteModel):
    """A rental contract between a unit, a tenant, and a landlord."""

    unit = models.ForeignKey(
        "properties.Unit",
        on_delete=models.PROTECT,
        related_name="leases",
        help_text="Which flat is being rented. PROTECT — cannot delete a unit "
        "while a lease exists.",
    )
    tenant = models.ForeignKey(
        "tenants.Tenant",
        on_delete=models.PROTECT,
        related_name="leases",
        help_text="Who is renting. PROTECT — cannot delete a tenant while a "
        "lease exists.",
    )
    landlord = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="leases_as_landlord",
        help_text="The property owner.",
    )
    start_date = models.DateField(help_text="Lease start date.")
    end_date = models.DateField(help_text="Lease end date.")
    rent = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal("0.00"),
        help_text="Monthly rent in Taka.",
    )
    advance = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal("0.00"),
        help_text="Advance / security deposit held in Taka.",
    )
    status = models.CharField(
        max_length=16,
        choices=LeaseStatus.choices,
        default=LeaseStatus.DRAFT,
        help_text="draft / active / ended / terminated.",
    )
    signed_pdf_ref = models.CharField(
        max_length=255,
        blank=True,
        default="",
        help_text="Pointer to the signed agreement PDF in object storage (P1 e-sign).",
    )

    objects = LeaseManager()  # type: ignore[misc]
    all_objects = AllObjectsManager()  # type: ignore[misc]

    class Meta:
        ordering = ("-created_at",)
        indexes = [
            models.Index(fields=["landlord", "status"]),
            models.Index(fields=["unit"]),
        ]

    def __str__(self) -> str:
        return f"Lease #{self.pk} · unit {self.unit_id} · tenant {self.tenant_id}"


class RentSchedule(TimeStampedModel):
    """One row per rent period (month) for a lease.

    Created by the schedule-generation job (T-003+). The ``period`` field is a
    ``YYYY-MM`` string so it can be sorted lexicographically and compared
    directly without date parsing. ``due_day`` is the calendar day-of-month the
    rent falls due; ``due_date`` is the resolved concrete date for this period.
    """

    lease = models.ForeignKey(
        Lease,
        on_delete=models.CASCADE,
        related_name="rent_schedules",
        help_text="Parent lease. CASCADE — deleting a lease removes its schedule rows.",
    )
    period = models.CharField(
        max_length=7,
        help_text='The rent month in YYYY-MM format, e.g. "2026-05".',
    )
    due_day = models.PositiveSmallIntegerField(
        help_text="Day of month rent is due (e.g. 5 means the 5th of each month).",
    )
    due_date = models.DateField(
        help_text="Concrete due date for this period (resolved from period + due_day).",
    )
    amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        help_text="Amount due in Taka for this period.",
    )
    status = models.CharField(
        max_length=16,
        choices=RentScheduleStatus.choices,
        default=RentScheduleStatus.PENDING,
        help_text="pending / requested / paid / overdue.",
    )
    sent_at = models.DateTimeField(
        null=True,
        blank=True,
        default=None,
        help_text="When the rent request was sent out (set when status → requested).",
    )

    class Meta:
        ordering = ("lease", "period")
        indexes = [
            models.Index(fields=["lease", "status"]),
        ]
        constraints = [
            models.UniqueConstraint(
                fields=["lease", "period"],
                name="leases_rentschedule_unique_lease_period",
            )
        ]

    def __str__(self) -> str:
        return f"RentSchedule · lease {self.lease_id} · {self.period}"
