"""Compliance domain models — PDPA / Domain 9 of ``06_database_schema.md``.

``ConsentRecord`` tracks who consented to what and when — regulatory requirement
under PDPA. It is **append-only**: records may never be deleted or soft-deleted,
ensuring an immutable audit trail.

``DataRequest`` tracks a data subject's right-of-access (export) or
right-of-erasure (delete) request, from submission through completion.
"""

from __future__ import annotations

from django.conf import settings
from django.db import models
from django.utils import timezone

from khatir.admin_portal.models import AdminUser
from khatir.core.models import TimeStampedModel

from .enums import ConsentType, DataRequestStatus, DataRequestType


class AppendOnlyQuerySet(models.QuerySet["ConsentRecord"]):
    """QuerySet that raises ``RuntimeError`` on any delete attempt."""

    def delete(self) -> tuple[int, dict[str, int]]:  # type: ignore[override]
        raise RuntimeError(
            "ConsentRecord is append-only and must never be deleted "
            "(PDPA regulatory requirement)."
        )


class AppendOnlyManager(models.Manager["ConsentRecord"]):
    """Manager whose default QuerySet blocks bulk deletes."""

    def get_queryset(self) -> AppendOnlyQuerySet:
        return AppendOnlyQuerySet(self.model, using=self._db)


class ConsentRecord(TimeStampedModel):
    """A logged consent event — who consented to what and when.

    Regulatory requirement: consent records are **append-only**. They must never
    be deleted (``delete()`` on an instance or queryset raises ``RuntimeError``).
    Use ``revoked_at`` to record withdrawal of consent.
    """

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="consent_records",
        help_text="The user who gave (or withdrew) consent.",
    )
    consent_type = models.CharField(
        max_length=32,
        choices=ConsentType.choices,
        help_text="What the user consented to (e.g. pdpa_data_collection).",
    )
    granted_at = models.DateTimeField(
        default=timezone.now,
        help_text="UTC timestamp when consent was granted.",
    )
    revoked_at = models.DateTimeField(
        null=True,
        blank=True,
        default=None,
        help_text="UTC timestamp when consent was revoked, if applicable.",
    )
    expires_at = models.DateTimeField(
        null=True,
        blank=True,
        default=None,
        help_text="UTC timestamp when this consent expires (if consent is time-limited).",
    )

    objects = AppendOnlyManager()

    class Meta:
        verbose_name = "consent record"
        verbose_name_plural = "consent records"
        ordering = ("-granted_at",)
        indexes = [
            models.Index(fields=["user"]),
            models.Index(fields=["consent_type"]),
        ]

    def __str__(self) -> str:
        return f"{self.user_id} consented to {self.consent_type} @ {self.granted_at:%Y-%m-%d %H:%M}"

    def delete(  # type: ignore[override]
        self, using: str | None = None, keep_parents: bool = False
    ) -> None:
        raise RuntimeError(
            "ConsentRecord is append-only and must never be deleted "
            "(PDPA regulatory requirement)."
        )


class DataRequest(TimeStampedModel):
    """A data subject's request to export or delete their personal data (PDPA).

    ``handled_by`` is a nullable FK to ``AdminUser`` — the compliance officer
    or admin staff member who processed the request. SET_NULL if the admin
    account is later removed.
    """

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="data_requests",
        help_text="The data subject making the request.",
    )
    request_type = models.CharField(
        max_length=8,
        choices=DataRequestType.choices,
        help_text="export or delete.",
    )
    status = models.CharField(
        max_length=16,
        choices=DataRequestStatus.choices,
        default=DataRequestStatus.PENDING,
        db_index=True,
        help_text="pending / processing / completed / rejected.",
    )
    sla_due = models.DateField(
        help_text="Date by which the request must be fulfilled (SLA deadline).",
    )
    completed_at = models.DateTimeField(
        null=True,
        blank=True,
        default=None,
        help_text="UTC timestamp when the request was completed or rejected.",
    )
    handled_by = models.ForeignKey(
        AdminUser,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        default=None,
        related_name="handled_data_requests",
        help_text="The admin staff member who processed this request.",
    )

    class Meta:
        verbose_name = "data request"
        verbose_name_plural = "data requests"
        ordering = ("-created_at",)
        indexes = [
            models.Index(fields=["user"]),
            models.Index(fields=["status"]),
        ]

    def __str__(self) -> str:
        return f"DataRequest({self.request_type}) by user {self.user_id} [{self.status}]"
