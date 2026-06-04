"""Rent receipt PDF rendering (EPIC-07 T-007, reuses the EPIC-05 T-003 seam).

``render_receipt_pdf(rent_request, payment) -> bytes`` renders a confirmed
payment into a single-page receipt PDF. It deliberately reuses the
dependency-free, deterministic PDF builder shipped for the DMP form
(:func:`khatir.dmpforms.pdf._render_pdf`) rather than introducing a second PDF
stack — same renderer, same storage seam (``core.storage.store_encrypted`` with
``kind="pdf"``), one place to harden fonts/layout later.

The layout is a fixed list of labelled fields plus the verifier line. Output is
deterministic for a given input (the caller stamps ``verified_at`` before
rendering, so two renders of the same persisted payment are byte-identical) so
the receipt can be golden-tested the same way the DMP form is.
"""

from __future__ import annotations

from dataclasses import dataclass

from khatir.dmpforms.pdf import PAGE_WIDTH, _render_pdf

from .models import Payment, RentRequest


@dataclass(frozen=True)
class ReceiptField:
    """One labelled line on the receipt and where its value is printed.

    ``(x, y)`` is the baseline of the value text in PDF points from the
    bottom-left of the page (Letter, 72pt = 1 inch).
    """

    label: str
    x: int
    y: int


# Ordered receipt layout. One spec per row; values are pulled from the request,
# lease and payment at render time. Changing a position is a template change.
RECEIPT_LAYOUT: tuple[ReceiptField, ...] = (
    ReceiptField("Receipt no", 72, 720),
    ReceiptField("Tenant", 72, 696),
    ReceiptField("Unit", 72, 672),
    ReceiptField("Landlord", 72, 648),
    ReceiptField("Period", 72, 624),
    ReceiptField("Amount (BDT)", 72, 600),
    ReceiptField("Verified by", 72, 576),
    ReceiptField("Verified at", 72, 552),
)


def _receipt_values(rent_request: RentRequest, payment: Payment) -> tuple[str, ...]:
    """Resolve the ordered values matching :data:`RECEIPT_LAYOUT`."""
    lease = rent_request.lease
    verified_at = payment.verified_at.isoformat() if payment.verified_at else ""
    verifier = getattr(payment.verified_by, "name", "") or str(payment.verified_by_id)
    return (
        str(payment.pk),
        getattr(lease.tenant, "name", "") or str(lease.tenant_id),
        getattr(lease.unit, "label", "") or str(lease.unit_id),
        getattr(lease.landlord, "name", "") or str(lease.landlord_id),
        rent_request.period,
        f"{rent_request.amount:.2f}",
        verifier,
        verified_at,
    )


def render_receipt_pdf(rent_request: RentRequest, payment: Payment) -> bytes:
    """Render a confirmed ``payment`` to deterministic receipt PDF bytes.

    Each field in :data:`RECEIPT_LAYOUT` is drawn at its fixed position as
    ``label: value``. Reuses the shared PDF builder; deterministic for a given
    persisted payment (no timestamps generated at render time).
    """
    values = _receipt_values(rent_request, payment)
    placements: list[tuple[int, int, str]] = [
        (PAGE_WIDTH // 2 - 80, 760, "Khatir Rent Receipt")
    ]
    for spec, value in zip(RECEIPT_LAYOUT, values, strict=True):
        placements.append((spec.x, spec.y, f"{spec.label}: {value}"))
    return _render_pdf(placements)


__all__ = ["render_receipt_pdf", "ReceiptField", "RECEIPT_LAYOUT"]
