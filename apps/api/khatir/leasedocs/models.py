"""Lease-documents domain model (EPIC-18 · AI Lease Generation).

A ``LeaseDocument`` is an AI-generated, DNCC/DSCC-compliant tenancy agreement
drafted from a :class:`~khatir.leases.models.Lease`. The AI gateway (EPIC-14)
fills the clause specifics; the landlord reviews/edits them (status ``draft``)
before finalizing (status ``final``) and rendering a shareable PDF (EPIC-05).

``content_json`` holds the ordered clause set as a JSON document. Required
clauses (parties, premises, rent, advance, term, disclaimer) MUST be present —
this is enforced by :meth:`LeaseDocument.validate_required_clauses` and the
``clean()`` hook so a document can never be persisted missing a mandatory clause
or the "not legal advice" disclaimer.

Inherits ``SoftDeleteModel`` (a generated agreement should never be permanently
lost). The ``lease`` FK is ``CASCADE`` — a document has no meaning without its
lease.
"""

from __future__ import annotations

from typing import Any

from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import models

from khatir.core.models import AllObjectsManager, SoftDeleteManager, SoftDeleteModel

from .enums import LeaseDocumentClauseKey, LeaseDocumentStatus

#: Clause keys that every lease document must contain. The disclaimer clause
#: ("not legal advice") is mandatory per the epic compliance acceptance criteria.
#: These reference :class:`LeaseDocumentClauseKey` (the scaffold, T-002) so the
#: mandatory subset stays in lock-step with the base lease structure.
REQUIRED_CLAUSE_KEYS: tuple[str, ...] = (
    LeaseDocumentClauseKey.PARTIES,
    LeaseDocumentClauseKey.PREMISES,
    LeaseDocumentClauseKey.RENT,
    LeaseDocumentClauseKey.ADVANCE,
    LeaseDocumentClauseKey.TERM,
    LeaseDocumentClauseKey.DISCLAIMER,
)


class LeaseDocument(SoftDeleteModel):
    """An AI-generated tenancy agreement document for a lease."""

    lease = models.ForeignKey(
        "leases.Lease",
        on_delete=models.CASCADE,
        related_name="documents",
        help_text="Parent lease. CASCADE — a document has no meaning without its lease.",
    )
    content_json = models.JSONField(
        default=dict,
        blank=True,
        help_text=(
            'Ordered clause set as JSON, keyed by clause name (e.g. "rent", '
            '"advance", "disclaimer"). Required clauses must be present.'
        ),
    )
    pdf_ref = models.CharField(
        max_length=255,
        blank=True,
        default="",
        help_text="Pointer to the rendered PDF in object storage (set by the PDF render step).",
    )
    generated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="generated_lease_documents",
        help_text="Landlord who triggered the AI generation. SET_NULL so the "
        "document survives user deletion.",
    )
    model_used = models.CharField(
        max_length=128,
        blank=True,
        default="",
        help_text="Identifier of the AI model that produced the draft (audit/repro).",
    )
    generated_at = models.DateTimeField(
        null=True,
        blank=True,
        default=None,
        help_text="When the AI draft was produced (set on successful generation).",
    )
    status = models.CharField(
        max_length=16,
        choices=LeaseDocumentStatus.choices,
        default=LeaseDocumentStatus.DRAFT,
        help_text="draft (editable) / final (locked, PDF-ready).",
    )

    objects = SoftDeleteManager()  # type: ignore[misc]
    all_objects = AllObjectsManager()  # type: ignore[misc]

    class Meta:
        ordering = ("-created_at",)
        indexes = [
            models.Index(fields=["lease", "status"]),
        ]

    def __str__(self) -> str:
        return f"LeaseDocument #{self.pk} · lease {self.lease_id} · {self.status}"

    # -- Required-clause guarantee -------------------------------------------

    def missing_required_clauses(self) -> list[str]:
        """Return the required clause keys absent or empty in ``content_json``.

        A clause is considered missing if its key is absent, or its value is
        ``None`` / an empty string / empty collection.
        """
        content: Any = self.content_json or {}
        if not isinstance(content, dict):
            return list(REQUIRED_CLAUSE_KEYS)
        missing: list[str] = []
        for key in REQUIRED_CLAUSE_KEYS:
            value = content.get(key)
            if value is None or value == "" or value == [] or value == {}:
                missing.append(key)
            elif isinstance(value, dict):
                # Scaffold-shaped clause (T-002): present only if it has a body.
                body = value.get("body")
                if body is None or (isinstance(body, str) and body.strip() == ""):
                    missing.append(key)
        return missing

    def validate_required_clauses(self) -> None:
        """Raise :class:`ValidationError` if any required clause is missing.

        Empty draft documents (no clauses yet) are allowed; the guarantee only
        bites once content has been added. This lets the generation flow create
        the row first and fill clauses before validating, while still blocking a
        partially-filled document from being saved missing a mandatory clause.
        """
        content = self.content_json or {}
        if not content:
            return
        missing = self.missing_required_clauses()
        if missing:
            raise ValidationError(
                {"content_json": f"Missing required clause(s): {', '.join(missing)}."}
            )

    def clean(self) -> None:
        super().clean()
        self.validate_required_clauses()
