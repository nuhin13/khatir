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

from typing import Any

from django.db import transaction
from django.utils import timezone

from khatir.ai_providers.client import AIGatewayResult, call_gateway
from khatir.ai_providers.enums import AICategory

from .models import LeaseDocument
from .scaffold import (
    SCAFFOLD_BY_KEY,
    build_scaffold_content,
    ensure_required_clauses,
)

__all__ = ["build_lease_prompt", "generate_lease_document"]


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
    return document
