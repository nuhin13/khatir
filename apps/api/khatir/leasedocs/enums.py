"""Lease-documents domain enums (EPIC-18).

Domain-specific (used only by ``LeaseDocument``), so they live in the owning app
rather than ``khatir.core.enums``. Wire values are lowercase snake_case strings,
never integers — consistent with ``docs/architecture/enums.md``.
"""

from django.db import models


class LeaseDocumentStatus(models.TextChoices):
    """Lifecycle status of an AI-generated tenancy agreement document."""

    DRAFT = "draft", "Draft"
    FINAL = "final", "Final"


class LeaseDocumentClauseKey(models.TextChoices):
    """Canonical clause-section keys of the compliant base lease scaffold.

    These are the ordered sections of a DNCC/DSCC-aware tenancy agreement. The
    ``parties``/``premises``/``rent``/``advance``/``term``/``disclaimer`` subset
    is mandatory (see ``models.REQUIRED_CLAUSE_KEYS``); ``obligations`` /
    ``termination`` / ``dispute`` are strongly-recommended sections the scaffold
    still seeds. Wire values are lowercase snake_case strings.
    """

    PARTIES = "parties", "Parties"
    PREMISES = "premises", "Premises"
    RENT = "rent", "Rent"
    ADVANCE = "advance", "Advance / Security Deposit"
    TERM = "term", "Term"
    OBLIGATIONS = "obligations", "Obligations"
    TERMINATION = "termination", "Termination"
    DISPUTE = "dispute", "Dispute Resolution"
    DISCLAIMER = "disclaimer", "Disclaimer"
