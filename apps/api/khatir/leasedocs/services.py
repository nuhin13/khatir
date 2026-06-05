"""AI lease generation service (EPIC-18 · T-003).

:func:`generate_lease_document` is the single backend entry-point for turning a
:class:`~khatir.leases.models.Lease` into a draft :class:`LeaseDocument`:

1. **Build a prompt** from the lease's concrete data (parties, premises, rent,
   advance, term, jurisdiction) plus the bilingual base scaffold (T-002). The
   scaffold travels alongside the prompt so the model knows which clause keys to
   return and what each placeholder means.
2. **Call the AI gateway** for the ``lease`` category (EPIC-14.T-007). All vendor
   routing/fallback/usage-logging lives in the gateway; this service only sends a
   normalised payload and reads back the normalised result.
3. **Parse** the gateway's returned clause map into ``content_json`` shaped like
   the scaffold (``{clause_key: {title_en, title_bn, body, order, required}}``).
4. **Guarantee required clauses.** :func:`ensure_required_clauses` back-fills any
   required clause (including the mandatory "not legal advice" disclaimer) the AI
   omitted, falling back to the scaffold's placeholder body so the document can
   never be persisted missing a mandatory clause.
5. **Store a draft.** A ``LeaseDocument`` is created with ``status=draft`` for the
   landlord to review/edit before finalizing (T-004).

The gateway is the only external dependency; tests mock it at the
``call_gateway`` boundary so they never open a socket.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from django.core.exceptions import ValidationError as DjangoValidationError
from django.db import transaction
from django.utils import timezone

from khatir.ai_providers.client import AIGatewayResult, call_gateway
from khatir.ai_providers.enums import AICategory
from khatir.core import storage
from khatir.core.audit import audit
from khatir.core.exceptions import ValidationError as AppValidationError

from .models import LeaseDocument
from .pdf import render_lease_pdf
from .scaffold import (
    SCAFFOLD_BY_KEY,
    build_scaffold_content,
    ensure_required_clauses,
)

# Signed-URL lifetime for rendered lease PDFs (modest, mirroring EPIC-05).
PDF_URL_TTL_SECONDS = storage.DEFAULT_TTL_SECONDS

__all__ = [
    "build_lease_prompt",
    "generate_lease_document",
    "edit_lease_document",
    "render_lease_document_pdf",
    "RenderedLeasePdf",
    "PDF_URL_TTL_SECONDS",
]


def _lease_facts(lease: Any) -> dict[str, Any]:
    """Extract the lease-specific facts the AI needs to fill the scaffold.

    Pulls from related ``unit``/``building``/``tenant``/``landlord`` rows. Money
    is rendered as plain strings (Taka) and dates as ISO ``YYYY-MM-DD``. Missing
    relations degrade gracefully to empty strings rather than raising, so a
    partially-populated lease can still be drafted.
    """
    unit = getattr(lease, "unit", None)
    building = getattr(unit, "building", None) if unit is not None else None
    tenant = getattr(lease, "tenant", None)
    landlord = getattr(lease, "landlord", None)

    premises_bits = [
        getattr(building, "name", "") or "",
        getattr(unit, "label", "") or "",
        getattr(building, "address", "") or "",
    ]
    premises_address = ", ".join(bit for bit in premises_bits if bit)

    return {
        "landlord_name": getattr(landlord, "name", "") or "",
        "tenant_name": getattr(tenant, "name", "") or "",
        "premises_address": premises_address,
        "city_corporation": getattr(building, "area", "") or "",
        "rent_amount": str(getattr(lease, "rent", "") or ""),
        "advance_amount": str(getattr(lease, "advance", "") or ""),
        "start_date": lease.start_date.isoformat() if getattr(lease, "start_date", None) else "",
        "end_date": lease.end_date.isoformat() if getattr(lease, "end_date", None) else "",
    }


def build_lease_prompt(lease: Any) -> dict[str, Any]:
    """Build the normalised gateway payload for generating ``lease``'s document.

    The payload carries the structured lease ``facts`` (so the model can fill
    placeholders deterministically) and the bilingual ``scaffold`` (the clause
    keys + placeholder bodies the model should return). Keeping this structured —
    rather than a single opaque prose string — lets the gateway and tests reason
    about exactly what was sent.
    """
    return {
        "category": AICategory.LEASE.value,
        "facts": _lease_facts(lease),
        "scaffold": build_scaffold_content(),
    }


def _coerce_clauses(data: dict[str, Any]) -> dict[str, Any]:
    """Normalise the gateway's returned clause data into scaffold-shaped clauses.

    The gateway returns ``data`` whose ``clauses`` (or, defensively, the data dict
    itself) maps clause keys to either a scaffold-shaped dict or a bare body
    string. Bare strings are wrapped into a dict using the scaffold's titles/order
    so the persisted ``content_json`` is uniform. Unknown clause keys are passed
    through unchanged so a model returning an extra section is not silently lost.
    """
    raw = data.get("clauses")
    if not isinstance(raw, dict):
        # Tolerate a gateway that returns the clause map at the top level.
        raw = {k: v for k, v in data.items() if k != "clauses"}

    clauses: dict[str, Any] = {}
    for key, value in raw.items():
        if isinstance(value, dict):
            clauses[key] = value
        elif isinstance(value, str):
            spec = SCAFFOLD_BY_KEY.get(key)
            if spec is not None:
                clause = dict(spec)
                clause["body"] = value
                clauses[key] = clause
            else:
                clauses[key] = {"body": value}
        # Other shapes (None, lists) are dropped → back-filled by the scaffold.
    return clauses


@transaction.atomic
def generate_lease_document(lease: Any, *, generated_by: Any | None = None) -> LeaseDocument:
    """Generate a draft :class:`LeaseDocument` for ``lease`` via the AI gateway.

    Builds the prompt, calls the gateway (``lease`` category), parses the returned
    clauses into the scaffold shape, guarantees the required-clause set (falling
    back to scaffold placeholder text for anything the AI omitted), and stores the
    result as a ``draft`` document.

    Args:
        lease: The :class:`~khatir.leases.models.Lease` to draft a document for.
        generated_by: The landlord who triggered generation (recorded for audit).
            Defaults to the lease's landlord when not supplied.

    Returns:
        The persisted draft :class:`LeaseDocument`.

    Raises:
        AIGatewayError: propagated unchanged when the gateway is unreachable,
            misconfigured, or returns an error — the caller decides how to surface
            it; no partial document is written (the transaction rolls back).
    """
    payload = build_lease_prompt(lease)
    result: AIGatewayResult = call_gateway(AICategory.LEASE, payload)

    parsed = _coerce_clauses(result.data)
    content_json = ensure_required_clauses(parsed)

    document = LeaseDocument(
        lease=lease,
        content_json=content_json,
        generated_by=generated_by if generated_by is not None else getattr(lease, "landlord", None),
        model_used=result.model_name,
        generated_at=timezone.now(),
    )
    document.full_clean(exclude=["lease", "generated_by"])
    document.save()

    audit(
        actor=generated_by if generated_by is not None else getattr(lease, "landlord", None),
        action="leasedocument.generate",
        target=document,
        before=None,
        after={"lease_id": lease.pk, "model_used": result.model_name},
    )
    return document


# ── Edit clauses (T-004 · PATCH /lease-documents/{id}) ──────────────────────


def edit_lease_document(
    document: LeaseDocument,
    *,
    clauses: dict[str, Any],
    actor: Any | None = None,
) -> LeaseDocument:
    """Apply landlord clause edits to a ``draft`` ``document`` and persist.

    ``clauses`` maps clause keys to either a scaffold-shaped dict or a bare body
    string; each is merged onto the existing ``content_json`` (bare strings are
    wrapped using the scaffold's titles/order so the stored shape stays uniform).
    The required-clause guarantee is re-asserted via ``full_clean`` so an edit can
    never blank out a mandatory clause or the disclaimer. The change is audited
    (``leasedocument.edit``) with a before/after clause snapshot.

    Only ``draft`` documents are editable; ``final`` documents are locked
    (enforced by the caller/serializer). Returns the saved document.
    """
    before = dict(document.content_json or {})
    merged = dict(before)
    merged.update(_coerce_clauses({"clauses": clauses}))

    document.content_json = merged
    try:
        document.full_clean(exclude=["lease", "generated_by"])
    except DjangoValidationError as exc:
        # Surface the required-clause guarantee as a 400 (app envelope), not a 500.
        raise AppValidationError(str(exc.messages[0] if exc.messages else exc)) from exc
    with transaction.atomic():
        document.save(update_fields=["content_json", "updated_at"])

    audit(
        actor=actor,
        action="leasedocument.edit",
        target=document,
        before={"clauses": sorted(before.keys())},
        after={"clauses": sorted(merged.keys())},
    )
    return document


# ── Render PDF (T-004 · POST /lease-documents/{id}/pdf) ─────────────────────


@dataclass(frozen=True)
class RenderedLeasePdf:
    """Result of a render: the document and a signed download URL."""

    document: LeaseDocument
    signed_url: str


def render_lease_document_pdf(
    document: LeaseDocument,
    *,
    actor: Any | None = None,
    ttl: int = PDF_URL_TTL_SECONDS,
) -> RenderedLeasePdf:
    """Render ``document`` to a PDF, store it encrypted, and return a signed URL.

    Re-validates the required-clause set (the disclaimer must be present in the
    rendered PDF, T-010), renders deterministic bytes (EPIC-05 PDF approach),
    stores them encrypted-at-rest via :mod:`khatir.core.storage`, records the
    opaque key on ``pdf_ref``, and returns a time-limited signed download URL. The
    render is audited (``leasedocument.pdf``).
    """
    document.validate_required_clauses()
    pdf_bytes = render_lease_pdf(document)
    pdf_ref = storage.store_encrypted(pdf_bytes, kind="pdf")

    with transaction.atomic():
        document.pdf_ref = pdf_ref
        document.save(update_fields=["pdf_ref", "updated_at"])

    audit(
        actor=actor,
        action="leasedocument.pdf",
        target=document,
        before=None,
        after={"lease_id": document.lease_id, "pdf_ref": pdf_ref},
    )

    url = storage.signed_url(pdf_ref, ttl=ttl)
    return RenderedLeasePdf(document=document, signed_url=url)
