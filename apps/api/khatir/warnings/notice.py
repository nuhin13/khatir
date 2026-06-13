"""Warning-notice PDF rendering (EPIC-20 T-003, reuses the EPIC-05 T-003 seam).

``render_notice_pdf(warning) -> bytes`` renders a private landlord-to-tenant
warning into a single-page notice PDF. It deliberately reuses the
dependency-free, deterministic PDF builder shipped for the DMP form
(:func:`khatir.dmpforms.pdf._render_pdf`) rather than introducing a second PDF
stack — same renderer, same storage seam (``core.storage.store_encrypted`` with
``kind="pdf"``), one place to harden fonts/layout later.

The notice carries the parties (landlord + tenant), the warning type, the
reason, the issue date, and a mandatory legal **disclaimer** (task §15): this is
a *private* notice between landlord and tenant, not a legal judgment. Output is
deterministic for a given persisted warning (``issued_at`` is stamped at create
time, never at render time) so the notice can be golden-tested like the DMP
form and the rent receipt.
"""

from __future__ import annotations

from dataclasses import dataclass

from khatir.dmpforms.pdf import PAGE_WIDTH, _render_pdf

from .enums import WarningType
from .models import Warning

#: Mandatory legal disclaimer printed on every notice (task §15). This is a
#: private notice between landlord and tenant, not a legal judgment.
DISCLAIMER = (
    "Disclaimer: This is a private notice between landlord and tenant, "
    "not a legal judgment."
)


@dataclass(frozen=True)
class NoticeField:
    """One labelled line on the notice and where its value is printed.

    ``(x, y)`` is the baseline of the value text in PDF points from the
    bottom-left of the page (Letter, 72pt = 1 inch).
    """

    label: str
    x: int
    y: int


# Ordered notice layout. One spec per row; values are resolved from the warning,
# its lease and parties at render time. Changing a position is a template change.
NOTICE_LAYOUT: tuple[NoticeField, ...] = (
    NoticeField("Notice no", 72, 720),
    NoticeField("Landlord", 72, 696),
    NoticeField("Tenant", 72, 672),
    NoticeField("Warning type", 72, 648),
    NoticeField("Issued", 72, 624),
    NoticeField("Reason", 72, 600),
)


def _notice_values(warning: Warning) -> tuple[str, ...]:
    """Resolve the ordered values matching :data:`NOTICE_LAYOUT`."""
    landlord = getattr(warning.landlord, "name", "") or str(warning.landlord_id)
    tenant = getattr(warning.tenant, "name", "") or str(warning.tenant_id)
    type_label = WarningType(warning.warning_type).label
    issued = warning.issued_at.isoformat() if warning.issued_at else ""
    return (
        str(warning.pk),
        landlord,
        tenant,
        type_label,
        issued,
        warning.reason,
    )


def render_notice_pdf(warning: Warning) -> bytes:
    """Render ``warning`` to deterministic warning-notice PDF bytes.

    Each field in :data:`NOTICE_LAYOUT` is drawn at its fixed position as
    ``label: value``; the mandatory :data:`DISCLAIMER` is printed at the foot.
    Reuses the shared PDF builder; deterministic for a given persisted warning
    (no timestamps generated at render time).
    """
    values = _notice_values(warning)
    placements: list[tuple[int, int, str]] = [
        (PAGE_WIDTH // 2 - 90, 760, "Khatir Warning Notice")
    ]
    for spec, value in zip(NOTICE_LAYOUT, values, strict=True):
        placements.append((spec.x, spec.y, f"{spec.label}: {value}"))
    placements.append((72, 96, DISCLAIMER))
    return _render_pdf(placements)


__all__ = ["render_notice_pdf", "NoticeField", "NOTICE_LAYOUT", "DISCLAIMER"]
