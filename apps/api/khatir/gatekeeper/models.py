"""Gatekeeper domain models — caretaker assignments + visitor entries.

A ``CaretakerAssignment`` links a caretaker ``User`` to a ``Building`` they are
trusted to operate the gate for; ``assigned_by`` records the owner/manager who
made the assignment. A ``VisitorEntry`` is a single logged visitor at a building
(optionally tied to a unit), moving through ``pending → approved/denied``.

The visitor's photo is **personal data**: only an opaque, encrypted pointer to
the image in object storage is stored (``photo_ref_enc``) — there is no plaintext
column. Use :meth:`VisitorEntry.set_photo_ref` / :meth:`VisitorEntry.get_photo_ref`.

Both tables are caretaker-scoped (assigned buildings only) through their
managers' ``for_user`` — see ``managers.py``. Writes are audited via
``core.audit.audit`` by the service/endpoint layer (wired in later tasks);
``visitor.log`` is the sanctioned action string (``enums.md``).
"""

from __future__ import annotations

from django.conf import settings
from django.db import models

from khatir.core.encryption import decrypt, encrypt
from khatir.core.models import TimeStampedModel
from khatir.properties.models import Building, Unit

from .enums import CaretakerAssignmentStatus, VisitorEntryStatus
from .managers import CaretakerAssignmentManager, VisitorEntryManager


class CaretakerAssignment(TimeStampedModel):
    """A caretaker's assignment to operate the gate for one building."""

    caretaker = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="caretaker_assignments",
        help_text="The caretaker User assigned to the building.",
    )
    building = models.ForeignKey(
        Building,
        on_delete=models.CASCADE,
        related_name="caretaker_assignments",
        help_text="The building this caretaker operates the gate for.",
    )
    assigned_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        default=None,
        related_name="caretaker_assignments_made",
        help_text="The owner/manager who created this assignment.",
    )
    status = models.CharField(
        max_length=16,
        choices=CaretakerAssignmentStatus.choices,
        default=CaretakerAssignmentStatus.ACTIVE,
        db_index=True,
        help_text="active / revoked.",
    )

    objects = CaretakerAssignmentManager()

    class Meta:
        verbose_name = "caretaker assignment"
        verbose_name_plural = "caretaker assignments"
        ordering = ("-created_at",)
        constraints = [
            models.UniqueConstraint(
                fields=["caretaker", "building"],
                name="uniq_caretaker_building",
            ),
        ]
        indexes = [
            models.Index(fields=["caretaker", "status"]),
            models.Index(fields=["building", "status"]),
        ]

    def __str__(self) -> str:
        return f"Caretaker {self.caretaker_id} @ building {self.building_id} [{self.status}]"


class VisitorEntry(TimeStampedModel):
    """A single logged visitor at a building, awaiting/holding approval."""

    building = models.ForeignKey(
        Building,
        on_delete=models.CASCADE,
        related_name="visitor_entries",
        help_text="The building the visitor is entering.",
    )
    unit = models.ForeignKey(
        Unit,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        default=None,
        related_name="visitor_entries",
        help_text="The unit being visited, if known.",
    )
    visitor_name = models.CharField(
        max_length=120,
        help_text="Name the visitor gave at the gate.",
    )
    purpose = models.CharField(
        max_length=255,
        blank=True,
        default="",
        help_text="Reason for the visit (free text).",
    )
    photo_ref_enc = models.BinaryField(
        null=True,
        blank=True,
        default=None,
        editable=False,
        help_text="Encrypted pointer to the visitor's photo in object storage. "
        "Set via set_photo_ref(); never a plaintext column.",
    )
    status = models.CharField(
        max_length=16,
        choices=VisitorEntryStatus.choices,
        default=VisitorEntryStatus.PENDING,
        db_index=True,
        help_text="pending / approved / denied.",
    )
    logged_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        default=None,
        related_name="visitor_entries_logged",
        help_text="The caretaker who logged this entry.",
    )

    objects = VisitorEntryManager()

    class Meta:
        verbose_name = "visitor entry"
        verbose_name_plural = "visitor entries"
        ordering = ("-created_at",)
        indexes = [
            models.Index(fields=["building", "status"]),
            models.Index(fields=["building", "created_at"]),
        ]

    def __str__(self) -> str:
        return f"{self.visitor_name} @ building {self.building_id} [{self.status}]"

    # --- photo_ref encryption (personal data) -------------------------------

    def set_photo_ref(self, raw: str | None) -> None:
        """Store the object-storage pointer encrypted at rest.

        Passing an empty/``None`` value clears the pointer.
        """
        if not raw:
            self.photo_ref_enc = None
            return
        self.photo_ref_enc = encrypt(raw).encode("utf-8")

    def get_photo_ref(self) -> str | None:
        """Return the decrypted storage pointer, or ``None`` if unset."""
        if not self.photo_ref_enc:
            return None
        token = bytes(self.photo_ref_enc).decode("utf-8")
        return decrypt(token)
