"""Tenants domain models — Domain 3 of ``06_database_schema.md``.

A ``Tenant`` is a renter's identity record. Because NID data is legally
protected, the full number is held **encrypted** in ``nid_number_enc`` (bytea)
and only a **masked** form (``****7788``) is ever shown or searched via
``nid_number_masked``. There is deliberately **no plaintext NID column** — the
encryption helper is wired in T-002, and the OCR/endpoints in T-005/T-007.

A tenant exists independently of any lease and may or may not have an app
account (``linked_user``). ``TenantFamilyMember`` rows are the household members
printed on the DMP (police) form; they CASCADE with their head tenant.
"""

from __future__ import annotations

from django.conf import settings
from django.db import models
from django.utils import timezone

from khatir.core.encryption import decrypt, encrypt, mask
from khatir.core.models import SoftDeleteModel, TimeStampedModel

from .enums import VerificationStatus
from .managers import TenantManager


class Tenant(SoftDeleteModel):
    """A renter's identity record — NID encrypted, masked for display."""

    name = models.CharField(max_length=120, help_text="Full name.")
    nid_number_enc = models.BinaryField(
        null=True,
        blank=True,
        default=None,
        editable=False,
        help_text="The real NID number, encrypted at rest (set in T-002). "
        "Never store the plaintext NID in any column.",
    )
    nid_number_masked = models.CharField(
        max_length=20,
        blank=True,
        default="",
        help_text="e.g. ****7788 — safe to show and search.",
    )
    dob = models.DateField(
        null=True,
        blank=True,
        default=None,
        help_text="Date of birth (from NID).",
    )
    address = models.TextField(
        blank=True,
        default="",
        help_text="Permanent address (from NID).",
    )
    photo_ref = models.CharField(
        max_length=255,
        blank=True,
        default="",
        help_text="Pointer to the encrypted NID image in object storage.",
    )
    verification_status = models.CharField(
        max_length=16,
        choices=VerificationStatus.choices,
        default=VerificationStatus.UNVERIFIED,
        help_text="unverified / matched / not_matched / error.",
    )
    verified_at = models.DateTimeField(
        null=True,
        blank=True,
        default=None,
        help_text="When EC verification happened.",
    )
    is_app_user = models.BooleanField(
        default=False,
        help_text="Has this tenant installed the app?",
    )
    linked_user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        default=None,
        related_name="tenant_profiles",
        help_text="Their app account, if any.",
    )

    objects = TenantManager()  # type: ignore[misc]

    class Meta:
        ordering = ("-created_at",)
        indexes = [models.Index(fields=["nid_number_masked"])]

    def __str__(self) -> str:
        return self.name

    # --- NID encryption / masking (T-002) -----------------------------------

    def set_nid(self, raw: str | None) -> None:
        """Encrypt and store the NID, deriving the masked form for display.

        Stores the Fernet ciphertext (UTF-8 bytes) in ``nid_number_enc`` and a
        ``****last4`` form in ``nid_number_masked``. Passing an empty/``None``
        value clears both. Never persists or returns the plaintext elsewhere.
        Call ``save()`` to persist.
        """
        if not raw:
            self.nid_number_enc = None
            self.nid_number_masked = ""
            return
        self.nid_number_enc = encrypt(raw).encode("utf-8")
        self.nid_number_masked = mask(raw)

    def get_nid(self) -> str | None:
        """Explicitly decrypt and return the full NID, or ``None`` if unset.

        This is the **only** path to the plaintext NID; it is deliberately a
        named method (never a serializer field or default representation) so
        callers must opt in and audit the access. Never log the return value.
        """
        if not self.nid_number_enc:
            return None
        token = bytes(self.nid_number_enc).decode("utf-8")
        return decrypt(token)

    # --- Verification status transition (EPIC-17 T-001) ---------------------

    def apply_verification_result(self, result: str, *, save: bool = True) -> None:
        """Transition ``verification_status`` from a verification outcome.

        ``result`` is a ``VerificationResult`` wire value
        (matched / not_matched / error) which maps 1:1 onto ``VerificationStatus``.
        A ``matched`` result also stamps ``verified_at``. Called by the
        verification flow after a ``VerificationLog`` is appended; never stores
        any raw EC data. Pass ``save=False`` to defer persistence.
        """
        try:
            status = VerificationStatus(result)
        except ValueError as exc:
            raise ValueError(f"Unknown verification result: {result!r}") from exc
        self.verification_status = status
        if status == VerificationStatus.MATCHED:
            self.verified_at = timezone.now()
        if save:
            self.save(update_fields=["verification_status", "verified_at", "updated_at"])


class TenantFamilyMember(TimeStampedModel):
    """A household member listed on the DMP form; CASCADE with the tenant."""

    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.CASCADE,
        related_name="family_members",
        help_text="The head tenant; deleting them removes their family rows.",
    )
    name = models.CharField(max_length=120, help_text="Family member name.")
    relation = models.CharField(
        max_length=40,
        help_text="Relationship to the tenant (e.g. spouse, child).",
    )

    class Meta:
        ordering = ("tenant", "name")

    def __str__(self) -> str:
        return f"{self.name} ({self.relation})"
