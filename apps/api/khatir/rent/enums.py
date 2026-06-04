"""Rent-collection enums — Domain 5 of ``06_database_schema.md``.

Domain-specific (used only by ``RentRequest``, ``PaymentProof`` and
``Payment``), so they live in the owning app rather than ``khatir.core.enums``.
Wire values are the single source of truth in ``docs/architecture/enums.md`` —
lowercase snake_case strings, never integers.
"""

from django.db import models


class RentRequestStatus(models.TextChoices):
    """Lifecycle status of a single ask-for-rent event."""

    SENT = "sent", "Sent"
    PROOF_SUBMITTED = "proof_submitted", "Proof submitted"
    VERIFIED = "verified", "Verified"
    REJECTED = "rejected", "Rejected"


class PaymentProofType(models.TextChoices):
    """The kind of evidence a tenant submits against a rent request."""

    BKASH_TXN = "bkash_txn", "bKash transaction"
    NAGAD_TXN = "nagad_txn", "Nagad transaction"
    SCREENSHOT = "screenshot", "Screenshot"
    PHOTO = "photo", "Photo"
    NOTE = "note", "Note"


class Channel(models.TextChoices):
    """Delivery channel a rent request was sent through."""

    INAPP = "inapp", "In-app"
    WHATSAPP = "whatsapp", "WhatsApp"
    SMS = "sms", "SMS"
    EMAIL = "email", "Email"
