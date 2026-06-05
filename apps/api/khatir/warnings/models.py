"""Warnings domain model (EPIC-20).

A ``Warning`` is a private notice issued by a landlord to their own tenant on a
specific lease — e.g. for late rent, a lease violation, or noise. Its scope is
intrinsically private: only the issuing landlord and that one tenant relate to
it. There is deliberately **no** global or shared structure and **no** field or
relation that would let warnings be aggregated across landlords — a warning is
strictly relational to one lease.

Inherits ``SoftDeleteModel`` (user-facing record). The lease / tenant / landlord
FKs are ``PROTECT`` — a warning is an issued legal-ish notice and must not be
silently orphaned by deleting the related party. ``notice_ref`` points at an
optional generated notice PDF in object storage (T-003). ``acknowledged_at``
records when the tenant acknowledged it.
"""

from __future__ import annotations

from django.conf import settings
from django.db import models

from khatir.core.models import SoftDeleteModel

from .enums import WarningType
from .managers import WarningManager


class Warning(SoftDeleteModel):
    """A private warning issued by a landlord to their own tenant."""

    lease = models.ForeignKey(
        "leases.Lease",
        on_delete=models.PROTECT,
        related_name="warnings",
        help_text="The lease this warning relates to. PROTECT — a warning is "
        "strictly scoped to one lease and is never orphaned.",
    )
    tenant = models.ForeignKey(
        "tenants.Tenant",
        on_delete=models.PROTECT,
        related_name="warnings",
        help_text="The tenant the warning was issued to.",
    )
    landlord = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="warnings_issued",
        help_text="The landlord who issued the warning. Sole owner of this "
        "private record.",
    )
    warning_type = models.CharField(
        max_length=16,
        choices=WarningType.choices,
        default=WarningType.OTHER,
        help_text="late_rent / lease_violation / noise / other.",
    )
    reason = models.TextField(help_text="Why the warning was issued.")
    issued_at = models.DateTimeField(
        auto_now_add=True,
        help_text="When the warning was issued.",
    )
    notice_ref = models.CharField(
        max_length=255,
        blank=True,
        default="",
        help_text="Pointer to the generated warning-notice PDF in object "
        "storage (T-003). Empty until generated.",
    )
    acknowledged_at = models.DateTimeField(
        null=True,
        blank=True,
        default=None,
        help_text="When the tenant acknowledged the warning, if at all.",
    )

    objects = WarningManager()

    class Meta:
        ordering = ("-issued_at",)
        indexes = [
            models.Index(fields=["landlord", "issued_at"]),
            models.Index(fields=["lease"]),
        ]

    def __str__(self) -> str:
        return f"Warning #{self.pk} · lease {self.lease_id} · {self.warning_type}"
