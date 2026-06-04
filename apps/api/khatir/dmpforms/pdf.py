"""DMP PDF rendering (EPIC-05 T-003 seam).

``render_dmp_pdf(dmp_data, template_version) -> bytes`` renders the assembled
:class:`~khatir.dmpforms.dto.DmpData` into PDF bytes.

The production renderer (T-003) is template-accurate with an embedded
Bangla-capable font and field positions matching the official DMP form,
verified field-by-field by T-010. This seam emits a **minimal, deterministic**
single-page PDF so the EPIC-05 T-005 pipeline (assemble → render → store →
record → signed URL) is runnable end-to-end; T-005's tests mock this function.
"""

from __future__ import annotations

from .dto import DmpData


def render_dmp_pdf(dmp_data: DmpData, template_version: str) -> bytes:
    """Render ``dmp_data`` to deterministic PDF bytes for ``template_version``.

    Deterministic: the same input always yields identical bytes (no timestamps,
    no random ids) so generated PDFs are reproducible and testable.
    """
    lines = [
        f"DMP Tenant Registration Form ({template_version})",
        f"Name: {dmp_data.tenant_name}",
        f"DOB: {dmp_data.dob}",
        f"Address: {dmp_data.permanent_address}",
        f"Building: {dmp_data.building_address} ({dmp_data.building_area})",
        f"Landlord: {dmp_data.landlord_name} {dmp_data.landlord_phone}",
    ]
    lines += [f"Family: {m.name} ({m.relation})" for m in dmp_data.family_members]

    text = "\n".join(lines)
    return _minimal_pdf(text)


def _minimal_pdf(text: str) -> bytes:
    """Build a minimal, valid, deterministic single-page PDF from ``text``.

    A hand-rolled PDF (no external renderer) keeps the seam dependency-free until
    T-003 swaps in the template-accurate, Bangla-capable renderer. Escapes the
    PDF string delimiters so arbitrary field content stays valid.
    """
    escaped = text.replace("\\", r"\\").replace("(", r"\(").replace(")", r"\)")
    body_lines = escaped.split("\n")
    # One Td-positioned Tj per line, stepping down the page.
    stream_parts = ["BT", "/F1 12 Tf", "72 720 Td", "14 TL"]
    for i, line in enumerate(body_lines):
        if i > 0:
            stream_parts.append("T*")
        stream_parts.append(f"({line}) Tj")
    stream_parts.append("ET")
    stream = "\n".join(stream_parts).encode("latin-1", errors="replace")

    objects: list[bytes] = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] "
        b"/Resources << /Font << /F1 5 0 R >> >> /Contents 4 0 R >>",
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


__all__ = ["render_dmp_pdf"]
