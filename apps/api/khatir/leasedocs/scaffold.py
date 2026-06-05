"""Compliant base lease clause scaffold (EPIC-18 · T-002).

This module defines a DNCC/DSCC-aware **base lease structure** — the ordered set
of clause sections every tenancy agreement must contain — together with bilingual
(Bangla + English) titles, guidance, and ``{{placeholder}}`` bodies that the AI
gateway (EPIC-14) fills with lease-specific specifics.

Why a scaffold? AI output varies. The scaffold is the contract's skeleton: it
*guarantees* that the required clauses exist and that the "not legal advice"
disclaimer is always present, regardless of what the model returns. The
generation flow seeds a draft from :func:`build_scaffold_content` and then
:func:`ensure_required_clauses` back-fills any clause the AI omitted.

The clause keys here are the single source of truth; the model's
``REQUIRED_CLAUSE_KEYS`` is the mandatory subset enforced at persistence time.

Wire format (``content_json``)::

    {
      "<clause_key>": {
        "title_en": str,
        "title_bn": str,
        "body": str,        # AI-filled; starts as the placeholder template
        "order": int,       # render order
        "required": bool,
      },
      ...
    }
"""

from __future__ import annotations

from typing import Any, TypedDict

from .enums import LeaseDocumentClauseKey

#: Default disclaimer body (mirrors the seeded ``lease_disclaimer_text`` config,
#: T-005). Kept here so the scaffold is self-sufficient even before config seed.
DEFAULT_DISCLAIMER_EN: str = (
    "This document is an AI-generated draft provided for convenience only and "
    "does not constitute legal advice. Khatir is not a law firm. Please consult "
    "a qualified lawyer before signing."
)
DEFAULT_DISCLAIMER_BN: str = (
    "এই নথিটি সুবিধার্থে একটি এআই-জেনারেটেড খসড়া এবং এটি কোনো আইনি পরামর্শ নয়। "
    "খাতির কোনো আইন প্রতিষ্ঠান নয়। স্বাক্ষরের আগে একজন যোগ্য আইনজীবীর পরামর্শ নিন।"
)


class ClauseSpec(TypedDict):
    """One scaffold clause: bilingual titles + a placeholder body template."""

    title_en: str
    title_bn: str
    body: str
    order: int
    required: bool


#: The compliant base lease structure, in render order. Bodies use
#: ``{{placeholder}}`` tokens the AI gateway substitutes from the lease data.
#: ``required`` clauses must survive into the persisted document; the rest are
#: strongly recommended sections the scaffold still seeds.
CLAUSE_SCAFFOLD: tuple[tuple[str, ClauseSpec], ...] = (
    (
        LeaseDocumentClauseKey.PARTIES,
        {
            "title_en": "Parties",
            "title_bn": "পক্ষগণ",
            "body": (
                "This tenancy agreement is made between the landlord "
                "{{landlord_name}} and the tenant {{tenant_name}}."
            ),
            "order": 10,
            "required": True,
        },
    ),
    (
        LeaseDocumentClauseKey.PREMISES,
        {
            "title_en": "Premises",
            "title_bn": "বাসস্থান",
            "body": (
                "The leased premises is {{premises_address}}, located within the "
                "{{city_corporation}} jurisdiction."
            ),
            "order": 20,
            "required": True,
        },
    ),
    (
        LeaseDocumentClauseKey.RENT,
        {
            "title_en": "Rent",
            "title_bn": "ভাড়া",
            "body": (
                "The monthly rent is BDT {{rent_amount}}, payable on or before "
                "the {{rent_due_day}} of each month."
            ),
            "order": 30,
            "required": True,
        },
    ),
    (
        LeaseDocumentClauseKey.ADVANCE,
        {
            "title_en": "Advance / Security Deposit",
            "title_bn": "অগ্রিম / জামানত",
            "body": (
                "The tenant pays an advance security deposit of BDT "
                "{{advance_amount}}, refundable on lawful termination subject to "
                "deductions for damages."
            ),
            "order": 40,
            "required": True,
        },
    ),
    (
        LeaseDocumentClauseKey.TERM,
        {
            "title_en": "Term",
            "title_bn": "মেয়াদ",
            "body": (
                "The lease term runs from {{start_date}} to {{end_date}} and may "
                "be renewed by mutual written consent."
            ),
            "order": 50,
            "required": True,
        },
    ),
    (
        LeaseDocumentClauseKey.OBLIGATIONS,
        {
            "title_en": "Obligations of the Parties",
            "title_bn": "পক্ষগণের দায়িত্ব",
            "body": (
                "The tenant shall use the premises lawfully, pay rent on time, "
                "and maintain it in good condition. The landlord shall ensure "
                "peaceful possession and carry out structural repairs."
            ),
            "order": 60,
            "required": False,
        },
    ),
    (
        LeaseDocumentClauseKey.TERMINATION,
        {
            "title_en": "Termination",
            "title_bn": "সমাপ্তি",
            "body": (
                "Either party may terminate this agreement by giving "
                "{{notice_period}} written notice. Material breach may permit "
                "earlier termination as allowed by law."
            ),
            "order": 70,
            "required": False,
        },
    ),
    (
        LeaseDocumentClauseKey.DISPUTE,
        {
            "title_en": "Dispute Resolution",
            "title_bn": "বিরোধ নিষ্পত্তি",
            "body": (
                "Disputes shall first be settled amicably; failing that, they "
                "shall be resolved under the applicable laws of Bangladesh "
                "before the competent courts of {{city_corporation}}."
            ),
            "order": 80,
            "required": False,
        },
    ),
    (
        LeaseDocumentClauseKey.DISCLAIMER,
        {
            "title_en": "Disclaimer",
            "title_bn": "দাবিত্যাগ",
            "body": DEFAULT_DISCLAIMER_EN + "\n\n" + DEFAULT_DISCLAIMER_BN,
            "order": 999,
            "required": True,
        },
    ),
)

#: Ordered clause keys defined by the scaffold (single source of truth).
SCAFFOLD_CLAUSE_KEYS: tuple[str, ...] = tuple(key for key, _ in CLAUSE_SCAFFOLD)

#: Lookup from clause key to its spec.
SCAFFOLD_BY_KEY: dict[str, ClauseSpec] = dict(CLAUSE_SCAFFOLD)


def build_scaffold_content() -> dict[str, ClauseSpec]:
    """Return a fresh, fully-populated scaffold ``content_json`` dict.

    The returned dict is a deep-ish copy (each clause spec is a new dict) safe to
    mutate by the caller (e.g. the AI generation flow fills the ``body`` fields).
    Every clause — including the mandatory "not legal advice" disclaimer — is
    present with its placeholder body, so the result already satisfies the
    model's required-clause guarantee.
    """
    return {key: dict(spec) for key, spec in CLAUSE_SCAFFOLD}  # type: ignore[misc]


def _is_empty_clause(value: Any) -> bool:
    """True if a clause value is absent/empty (no usable body)."""
    if value is None or value == "" or value == [] or value == {}:
        return True
    if isinstance(value, dict):
        body = value.get("body")
        return body is None or (isinstance(body, str) and body.strip() == "")
    return False


def ensure_required_clauses(content: dict[str, Any] | None) -> dict[str, Any]:
    """Merge AI/landlord-provided clauses over the scaffold, guaranteeing the
    required set.

    Any required clause that is missing or empty in ``content`` is back-filled
    from :data:`CLAUSE_SCAFFOLD` (placeholder body) so the document can never be
    persisted without its mandatory clauses or the disclaimer. Non-required
    clauses present in the scaffold are also seeded when absent, but extra
    clauses supplied by the caller are preserved. Clause ordering follows the
    scaffold; any caller-only keys are appended in stable order afterwards.

    This is the runtime counterpart to the model's
    ``validate_required_clauses`` — validation rejects a bad document; this
    *repairs* one so generation never fails on a clause the AI dropped.
    """
    provided: dict[str, Any] = dict(content or {})
    merged: dict[str, Any] = {}

    for key, spec in CLAUSE_SCAFFOLD:
        incoming = provided.pop(key, None)
        if _is_empty_clause(incoming):
            merged[key] = dict(spec)
        else:
            merged[key] = incoming

    # Preserve any caller-supplied clauses not part of the scaffold.
    for key, value in provided.items():
        merged[key] = value

    return merged
