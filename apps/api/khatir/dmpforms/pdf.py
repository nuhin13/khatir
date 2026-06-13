"""DMP PDF rendering (EPIC-05 T-003 seam, field-locked by T-010).

``render_dmp_pdf(dmp_data, template_version) -> bytes`` renders the assembled
:class:`~khatir.dmpforms.dto.DmpData` into PDF bytes.

The official DMP tenant-registration field list is documented and reconciled in
``documnets/docs/epics/EPIC-05-dmp-form/T-010-dmp-field-map.md``. :data:`FIELD_LAYOUT`
below is the machine-readable counterpart: one :class:`FieldSpec` per official
field, each with a fixed ``(x, y)`` position on a single Letter page. The golden
test (``tests/test_template_verification.py``) asserts every documented field is
present in this layout, that each value is rendered, and that output is
byte-for-byte deterministic — the field-by-field fidelity gate for the wedge.

The output is a hand-rolled, dependency-free, deterministic single-page PDF so
the EPIC-05 T-005 pipeline (assemble → render → store → record → signed URL) is
runnable end-to-end and golden-testable. Pixel-overlay confirmation against the
authoritative scanned master form is pending founder input (T-010 §15); only the
position constants below need confirming once the scan is in hand — the field
set and golden test are already locked.
"""

from __future__ import annotations

from dataclasses import dataclass

from .dto import DmpData

# Letter page in PDF points (72pt = 1 inch). Origin is bottom-left.
PAGE_WIDTH = 612
PAGE_HEIGHT = 792


@dataclass(frozen=True)
class FieldSpec:
    """One official DMP form field and where the renderer prints its value.

    ``key`` is the :class:`~khatir.dmpforms.dto.DmpData` attribute name (and the
    stable identifier the golden test asserts). ``label`` is the human caption
    drawn before the value. ``(x, y)`` is the baseline of the value text in PDF
    points from the bottom-left of the page.
    """

    key: str
    label: str
    x: int
    y: int


# Ordered field layout for DMP template version 2026.1. One spec per row 1–9 of
# the official field map (T-010 §3); family members render as a repeating block
# below the fixed fields. Changing any position is a template change → bump
# ``dmp_template_version``.
FIELD_LAYOUT: tuple[FieldSpec, ...] = (
    FieldSpec("tenant_name", "Tenant name", 72, 720),
    FieldSpec("nid_number", "NID number", 72, 696),
    FieldSpec("dob", "Date of birth", 72, 672),
    FieldSpec("permanent_address", "Permanent address", 72, 648),
    FieldSpec("present_address", "Present address", 72, 624),
    FieldSpec("building_address", "Building address", 72, 600),
    FieldSpec("building_area", "Area", 72, 576),
    FieldSpec("landlord_name", "Landlord name", 72, 552),
    FieldSpec("landlord_phone", "Landlord phone", 72, 528),
)

# First family-member row baseline and the step (in points) between rows.
FAMILY_BLOCK_TOP = 492
FAMILY_ROW_STEP = 20


def render_dmp_pdf(dmp_data: DmpData, template_version: str) -> bytes:
    """Render ``dmp_data`` to deterministic PDF bytes for ``template_version``.

    Each field in :data:`FIELD_LAYOUT` is drawn at its fixed position as
    ``label: value``; family members follow as a repeating block. Deterministic:
    the same input always yields identical bytes (no timestamps, no random ids).
    """
    placements: list[tuple[int, int, str]] = [
        (PAGE_WIDTH // 2 - 120, 760, f"DMP Tenant Registration Form ({template_version})")
    ]
    for spec in FIELD_LAYOUT:
        value = getattr(dmp_data, spec.key, "")
        placements.append((spec.x, spec.y, f"{spec.label}: {value}"))

    for i, member in enumerate(dmp_data.family_members):
        y = FAMILY_BLOCK_TOP - i * FAMILY_ROW_STEP
        placements.append((72, y, f"Family: {member.name} ({member.relation})"))

    return _render_pdf(placements)


def _render_pdf(placements: list[tuple[int, int, str]]) -> bytes:
    """Build a minimal, valid, deterministic single-page PDF.

    ``placements`` is a list of ``(x, y, text)`` — each drawn at its absolute
    baseline so the golden test can assert per-field positions. Escapes the PDF
    string delimiters so arbitrary field content stays valid.
    """
    stream_parts = ["BT", "/F1 12 Tf"]
    for x, y, text in placements:
        escaped = text.replace("\\", r"\\").replace("(", r"\(").replace(")", r"\)")
        stream_parts.append(f"1 0 0 1 {x} {y} Tm")
        stream_parts.append(f"({escaped}) Tj")
    stream_parts.append("ET")
    stream = "\n".join(stream_parts).encode("latin-1", errors="replace")

    objects: list[bytes] = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 "
        + f"{PAGE_WIDTH} {PAGE_HEIGHT}".encode("latin-1")
        + b"] /Resources << /Font << /F1 5 0 R >> >> /Contents 4 0 R >>",
        b"<< /Length "
        + str(len(stream)).encode("latin-1")
        + b" >>\nstream\n"
        + stream
        + b"\nendstream",
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
    ]

    out = bytearray(b"%PDF-1.4\n")
    offsets: list[int] = []
    for i, obj in enumerate(objects, start=1):
        offsets.append(len(out))
        out += f"{i} 0 obj\n".encode("latin-1") + obj + b"\nendobj\n"

    xref_pos = len(out)
    n = len(objects) + 1
    out += f"xref\n0 {n}\n".encode("latin-1")
    out += b"0000000000 65535 f \n"
    for off in offsets:
        out += f"{off:010d} 00000 n \n".encode("latin-1")
    out += f"trailer\n<< /Size {n} /Root 1 0 R >>\nstartxref\n{xref_pos}\n%%EOF".encode(
        "latin-1"
    )
    return bytes(out)


__all__ = ["render_dmp_pdf", "FieldSpec", "FIELD_LAYOUT"]
