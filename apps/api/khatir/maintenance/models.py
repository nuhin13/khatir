"""Maintenance domain models — Domain 6 of ``06_database_schema.md``.

A ``MaintenanceRequest`` captures a reported repair need on a unit (and
optionally the active lease at the time). The landlord resolves it and records
the cost, which T-002 will auto-create as an ``Expense`` with
``source=request``. Landlords can also log ``Expense`` rows directly
(``source=manual``) — e.g. annual painting — without a request.

Both models are user-facing records so they inherit ``SoftDeleteModel``.
The unit FK is ``PROTECT`` (cannot delete a unit while requests/expenses
exist). The lease FK on ``MaintenanceRequest`` is nullable ``SET_NULL``
(a lease may end before the request is resolved). Money is ``Decimal(12,2)``
in Bangladeshi Taka.

Index: ``Expense(unit, date)`` per the schema's index section;
``MaintenanceRequest(unit, status)`` for the standard filter pattern.
"""

from __future__ import annotations

from decimal import Decimal

from django.db import models

from khatir.core.models import SoftDeleteModel

from .enums import ExpenseCategory, ExpenseSource, MaintenanceCategory, MaintenanceStatus


class MaintenanceRequest(SoftDeleteModel):
    """A reported repair need on a unit."""

    unit = models.ForeignKey(
        "properties.Unit",
        on_delete=models.PROTECT,
        related_name="maintenance_requests",
        help_text="Which unit the request is for.",
    )
    lease = models.ForeignKey(
        "leases.Lease",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        default=None,
        related_name="maintenance_requests",
        help_text="The active lease at the time of the request, if any.",
    )
    category = models.CharField(
        max_length=16,
        choices=MaintenanceCategory.choices,
        default=MaintenanceCategory.OTHER,
        help_text="plumbing / electrical / paint / structural / appliance / utility / other.",
    )
    description = models.TextField(help_text="What's wrong.")
    photo_ref = models.CharField(
        max_length=255,
        blank=True,
        default="",
        help_text="Photo of the problem in object storage.",
    )
    status = models.CharField(
        max_length=16,
        choices=MaintenanceStatus.choices,
        default=MaintenanceStatus.OPEN,
        help_text="open / resolved.",
    )
    resolved_at = models.DateTimeField(
        null=True,
        blank=True,
        default=None,
        help_text="When the issue was fixed.",
    )
    resolution_cost = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        null=True,
        blank=True,
        default=None,
        help_text="Cost of fixing the issue in Taka. Feeds the auto-expense (T-002).",
    )
    resolution_note = models.TextField(
        blank=True,
        default="",
        help_text="Notes on the fix.",
    )

    class Meta:
        ordering = ("-created_at",)
        indexes = [models.Index(fields=["unit", "status"])]

    def __str__(self) -> str:
        return f"MaintenanceRequest #{self.pk} — {self.category} ({self.status})"


class Expense(SoftDeleteModel):
    """Money spent on a unit — from a maintenance request or logged directly."""

    unit = models.ForeignKey(
        "properties.Unit",
        on_delete=models.PROTECT,
        related_name="expenses",
        help_text="Which unit the expense is for.",
    )
    category = models.CharField(
        max_length=16,
        choices=ExpenseCategory.choices,
        default=ExpenseCategory.OTHER,
        help_text="plumbing / paint / electrical / structural / appliance / utility / other.",
    )
    amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal("0.00"),
        help_text="Cost in Bangladeshi Taka.",
    )
    date = models.DateField(help_text="When the expense was incurred.")
    source = models.CharField(
        max_length=8,
        choices=ExpenseSource.choices,
        default=ExpenseSource.MANUAL,
        help_text="request (from a maintenance request) / manual (direct landlord entry).",
    )
    note = models.TextField(
        blank=True,
        default="",
        help_text="Description of the expense.",
    )
    receipt_ref = models.CharField(
        max_length=255,
        blank=True,
        default="",
        help_text="Receipt image in object storage.",
    )

    class Meta:
        ordering = ("-date", "-created_at")
        indexes = [models.Index(fields=["unit", "date"])]

    def __str__(self) -> str:
        return f"Expense #{self.pk} — {self.category} ৳{self.amount}"
