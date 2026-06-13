"""Rent-collection domain models — Domain 5 of ``06_database_schema.md``.

This is the signature feature: collecting rent without forcing the tenant to
install anything. When rent is due, the landlord sends a ``RentRequest``; the
tenant opens a unique web link (``/r/{link_token}`` — no app, no login) and
submits a ``PaymentProof`` (a bKash transaction id, a screenshot, or a note).
The landlord reviews it and confirms; that confirmation creates a ``Payment``
record and a generated receipt.

``RentRequest.link_token`` is a secret, single-purpose token — it grants access
to exactly one request's page. It is populated by the T-002 service, not here,
so it is ``blank``/``default=""`` at the model layer while still carrying a
``unique`` constraint. Money is ``Decimal(12,2)`` in Taka.

All three models inherit ``TimeStampedModel`` — they are operational, append-y
records (events, evidence, confirmations) rather than user-editable documents,
so they carry ``created_at``/``updated_at`` but no soft-delete column. The FK to
the parent ``RentRequest`` is ``CASCADE`` (proofs and payments have no meaning
without their request); the FKs to ``Lease`` and ``RentSchedule`` are
``PROTECT``/``SET_NULL`` respectively so financial history is never silently
destroyed.
"""

from __future__ import annotations

from decimal import Decimal

from django.conf import settings
from django.db import models

from khatir.core.models import TimeStampedModel

from .enums import Channel, PaymentProofType, RentRequestStatus
from .managers import RentRequestManager


class RentRequest(TimeStampedModel):
    """A single ask-for-rent event sent to a tenant."""

    rent_schedule = models.ForeignKey(
        "leases.RentSchedule",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        default=None,
        related_name="rent_requests",
        help_text="The scheduled month this answers. Null for a one-off manual "
        "request. SET_NULL — clearing a schedule must not delete the request.",
    )
    lease = models.ForeignKey(
        "leases.Lease",
        on_delete=models.PROTECT,
        related_name="rent_requests",
        help_text="The lease this request belongs to. PROTECT — financial "
        "history is never silently destroyed.",
    )
    amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal("0.00"),
        help_text="Amount requested in Taka.",
    )
    period = models.CharField(
        max_length=7,
        help_text='The rent month in YYYY-MM format, e.g. "2026-05".',
    )
    link_token = models.CharField(
        max_length=255,
        unique=True,
        blank=True,
        default="",
        help_text="Secret single-purpose token in the tenant's web-link URL "
        "(/r/{token}). Populated by the T-002 service, not at create time.",
    )
    sent_via = models.CharField(
        max_length=16,
        choices=Channel.choices,
        default=Channel.WHATSAPP,
        help_text="Delivery channel: inapp / whatsapp / sms / email.",
    )
    sent_at = models.DateTimeField(
        null=True,
        blank=True,
        default=None,
        help_text="When the request was sent out.",
    )
    status = models.CharField(
        max_length=16,
        choices=RentRequestStatus.choices,
        default=RentRequestStatus.SENT,
        help_text="sent / proof_submitted / verified / rejected.",
    )
    reminder_count = models.PositiveSmallIntegerField(
        default=0,
        help_text="How many reminders have been sent for this request (T-008).",
    )
    last_reminded_at = models.DateTimeField(
        null=True,
        blank=True,
        default=None,
        help_text="When the most recent reminder was sent (T-008).",
    )

    objects = RentRequestManager()  # type: ignore[misc]

    class Meta:
        ordering = ("-created_at",)
        indexes = [
            models.Index(fields=["link_token"]),
            models.Index(fields=["lease", "status"]),
        ]

    def __str__(self) -> str:
        return f"RentRequest #{self.pk} · lease {self.lease_id} · {self.period}"


class PaymentProof(TimeStampedModel):
    """Evidence a tenant submits against a rent request."""

    rent_request = models.ForeignKey(
        RentRequest,
        on_delete=models.CASCADE,
        related_name="proofs",
        help_text="The request being answered. CASCADE — a proof has no meaning "
        "without its request.",
    )
    type = models.CharField(
        max_length=16,
        choices=PaymentProofType.choices,
        help_text="bkash_txn / nagad_txn / screenshot / photo / note.",
    )
    value = models.CharField(
        max_length=255,
        blank=True,
        default="",
        help_text="Transaction id or note text.",
    )
    photo_ref = models.CharField(
        max_length=255,
        blank=True,
        default="",
        help_text="Pointer to the screenshot/photo in object storage.",
    )
    submitted_at = models.DateTimeField(
        null=True,
        blank=True,
        default=None,
        help_text="When the tenant submitted this proof.",
    )

    class Meta:
        ordering = ("-created_at",)
        indexes = [
            models.Index(fields=["rent_request"]),
        ]

    def __str__(self) -> str:
        return f"PaymentProof #{self.pk} · request {self.rent_request_id} · {self.type}"


class Payment(TimeStampedModel):
    """The confirmed, verified payment for a settled rent request."""

    rent_request = models.ForeignKey(
        RentRequest,
        on_delete=models.CASCADE,
        related_name="payments",
        help_text="The settled request. CASCADE — a payment has no meaning "
        "without its request.",
    )
    verified_at = models.DateTimeField(
        null=True,
        blank=True,
        default=None,
        help_text="When the landlord confirmed the payment.",
    )
    verified_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="payments_verified",
        help_text="Who confirmed. PROTECT — keep the audit trail intact.",
    )
    receipt_ref = models.CharField(
        max_length=255,
        blank=True,
        default="",
        help_text="Pointer to the generated receipt PDF in object storage.",
    )

    class Meta:
        ordering = ("-created_at",)
        indexes = [
            models.Index(fields=["rent_request"]),
        ]

    def __str__(self) -> str:
        return f"Payment #{self.pk} · request {self.rent_request_id}"
