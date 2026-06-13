"""Verification domain models — EPIC-17 (NID/EC verification).

A ``VerificationLog`` records one EC verification attempt for a tenant. It is
deliberately **boolean-only**: the only outcome stored is matched / not_matched
/ error. The raw Election Commission payload (name, DOB, address, photo, NID
number, …) is **never** persisted in any column — only the opaque vendor
``provider_ref`` transaction id is kept, for audit/dispute purposes.

The log is **append-only**: rows may never be deleted or mutated, giving an
immutable audit trail (mirrors ``compliance.ConsentRecord``). On a successful
match the tenant's ``verification_status`` is flipped via
``Tenant.apply_verification_result``.
"""

from __future__ import annotations

from django.conf import settings
from django.db import models

from khatir.compliance.models import ConsentRecord
from khatir.core.models import TimeStampedModel
from khatir.tenants.models import Tenant

from .enums import VerificationResult


class AppendOnlyQuerySet(models.QuerySet["VerificationLog"]):
    """QuerySet that raises ``RuntimeError`` on any delete attempt."""

    def delete(self) -> tuple[int, dict[str, int]]:  # type: ignore[override]
        raise RuntimeError(
            "VerificationLog is append-only and must never be deleted "
            "(audit-trail requirement)."
        )


class AppendOnlyManager(models.Manager["VerificationLog"]):
    """Manager whose default QuerySet blocks bulk deletes."""

    def get_queryset(self) -> AppendOnlyQuerySet:
        return AppendOnlyQuerySet(self.model, using=self._db)


class VerificationLog(TimeStampedModel):
    """One EC verification attempt — boolean-only result, no raw EC data.

    Append-only: ``delete()`` on an instance or queryset raises ``RuntimeError``.
    There are deliberately **no** raw-EC columns (no name/dob/address/photo/nid);
    the only vendor data kept is the opaque ``provider_ref`` transaction id.
    """

    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.CASCADE,
        related_name="verification_logs",
        help_text="The tenant whose identity was verified.",
    )
    requested_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="verification_requests",
        help_text="The user who initiated the verification attempt.",
    )
    result = models.CharField(
        max_length=16,
        choices=VerificationResult.choices,
        help_text="Boolean-only outcome: matched / not_matched / error.",
    )
    provider_ref = models.CharField(
        max_length=128,
        blank=True,
        default="",
        help_text="Opaque vendor transaction id for audit/dispute. "
        "NOT the EC data itself — never store raw EC fields here.",
    )
    consent_record = models.ForeignKey(
        ConsentRecord,
        on_delete=models.PROTECT,
        related_name="verification_logs",
        help_text="The consent under which this verification was performed.",
    )

    objects = AppendOnlyManager()

    class Meta:
        verbose_name = "verification log"
        verbose_name_plural = "verification logs"
        ordering = ("-created_at",)
        indexes = [
            models.Index(fields=["tenant", "created_at"]),
            models.Index(fields=["result"]),
        ]

    def __str__(self) -> str:
        return f"{self.tenant_id} -> {self.result} @ {self.created_at:%Y-%m-%d %H:%M}"

    def delete(  # type: ignore[override]
        self, using: str | None = None, keep_parents: bool = False
    ) -> None:
        raise RuntimeError(
            "VerificationLog is append-only and must never be deleted "
            "(audit-trail requirement)."
        )
