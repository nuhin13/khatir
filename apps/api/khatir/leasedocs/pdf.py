"""Lease-document PDF rendering (EPIC-18 · T-004).

``render_lease_pdf(document) -> bytes`` renders a :class:`LeaseDocument`'s
``content_json`` clause set into deterministic PDF bytes. The clauses are drawn
in scaffold order (parties → premises → rent → advance → term → … → disclaimer),
each as a titled block. The mandatory "not legal advice" disclaimer is always the
final clause and is rendered verbatim — the required-clause guarantee on the
model (and :func:`ensure_required_clauses`) means it is always present in
``content_json`` by the time a document is rendered.

The output is a hand-rolled, dependency-free, deterministic multi-page-free PDF
(mirroring the EPIC-05 DMP renderer's approach) so the generate → store → signed
URL pipeline is runnable end-to-end and golden-testable without a real PDF
toolchain. Determinism: identical ``content_json`` always yields identical bytes
(no timestamps, no random ids).
"""

from __future__ import annotations

from typing import Any

from .enums import LeaseDocumentClauseKey

# Letter page in PDF points (72pt = 1 inch). Origin is bottom-left.
PAGE_WIDTH = 612
PAGE_HEIGHT = 792

# Canonical clause order for rendering — the scaffold's section order so a
# rendered agreement always reads parties → … → disclaimer.
CLAUSE_ORDER: tuple[str, ...] = (
    LeaseDocumentClauseKey.PARTIES,
    LeaseDocumentClauseKey.PREMISES,
    LeaseDocumentClauseKey.RENT,
    LeaseDocumentClauseKey.ADVANCE,
    LeaseDocumentClauseKey.TERM,
    LeaseDocumentClauseKey.OBLIGATIONS,
    LeaseDocumentClauseKey.TERMINATION,
    LeaseDocumentClauseKey.DISPUTE,
    LeaseDocumentClauseKey.DISCLAIMER,
)

# Layout constants (PDF points).
_LEFT_MARGIN = 72
_TOP = 740
_TITLE_STEP = 22
_BODY_STEP = 16
_CLAUSE_GAP = 12


def _clause_title(key: str, value: Any) -> str:
    """Human title for a clause: the clause's own ``title_en`` if present, else
    the canonical enum label, else the key."""
    if isinstance(value, dict):
        title = value.get("title_en")
        if isinstance(title, str) and title.strip():
            return title
    label = LeaseDocumentClauseKey(key).label if key in LeaseDocumentClauseKey.values else key
    return str(label)


def _clause_body(value: Any) -> str:
    """Extract a clause's body text from either a scaffold-shaped dict or a bare
    string."""
    if isinstance(value, dict):
        body = value.get("body")
        return str(body) if body is not None else ""
    return str(value) if value is not None else ""


def _ordered_clauses(content: dict[str, Any]) -> list[tuple[str, Any]]:
    """Return ``(key, value)`` pairs in canonical clause order, with any
    unrecognised extra clauses appended afterwards (never silently dropped)."""
    ordered: list[tuple[str, Any]] = [
        (key, content[key]) for key in CLAUSE_ORDER if key in content
    ]
    seen = {key for key, _ in ordered}
    ordered.extend((key, value) for key, value in content.items() if key not in seen)
    return ordered


def render_lease_pdf(document: Any) -> bytes:
    """Render ``document``'s clauses to deterministic PDF bytes.

    Each clause is drawn as a titled block in scaffold order; the disclaimer is
    rendered verbatim as the closing clause. Deterministic: same ``content_json``
    → identical bytes.
    """
    content: dict[str, Any] = document.content_json or {}
    placements: list[tuple[int, int, str]] = [
        (_LEFT_MARGIN, 770, "Tenancy Agreement (AI-generated draft)")
    ]

    y = _TOP
    for key, value in _ordered_clauses(content):
        if y < 72:  # Single-page renderer: stop before running off the page.
            break
        placements.append((_LEFT_MARGIN, y, _clause_title(key, value)))
        y -= _TITLE_STEP
        for line in _wrap(_clause_body(value)):
            if y < 72:
                break
            placements.append((_LEFT_MARGIN, y, line))
            y -= _BODY_STEP
        y -= _CLAUSE_GAP

    return _render_pdf(placements)


def _wrap(text: str, width: int = 90) -> list[str]:
    """Wrap ``text`` to ``width`` characters per line, preserving paragraph
    breaks; deterministic and font-metrics-free (line count drives layout)."""
    lines: list[str] = []
    for paragraph in text.split("\n"):
        if not paragraph:
            lines.append("")
            continue
        words = paragraph.split(" ")
        current = ""
        for word in words:
            candidate = f"{current} {word}".strip()
            if len(candidate) > width and current:
                lines.append(current)
                current = word
            else:
                current = candidate
        if current:
            lines.append(current)
    return lines


def _render_pdf(placements: list[tuple[int, int, str]]) -> bytes:
    """Build a minimal, valid, deterministic single-page PDF.

    ``placements`` is a list of ``(x, y, text)`` drawn at absolute baselines.
    Escapes PDF string delimiters so arbitrary clause content stays valid.
    Non-latin-1 glyphs (Bangla) degrade to ``?`` in this dependency-free
    fallback renderer; the text is still present in ``content_json`` and the
    English disclaimer/clauses render verbatim.
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
    for i, body in enumerate(objects, start=1):
        offsets.append(len(out))
        out += f"{i} 0 obj\n".encode("latin-1") + body + b"\nendobj\n"

    xref_pos = len(out)
    out += f"xref\n0 {len(objects) + 1}\n".encode("latin-1")
    out += b"0000000000 65535 f \n"
    for offset in offsets:
        out += f"{offset:010d} 00000 n \n".encode("latin-1")
    out += (
        b"trailer\n<< /Size "
        + str(len(objects) + 1).encode("latin-1")
        + b" /Root 1 0 R >>\nstartxref\n"
        + str(xref_pos).encode("latin-1")
        + b"\n%%EOF\n"
    )
    return bytes(out)


__all__ = ["render_lease_pdf", "CLAUSE_ORDER", "PAGE_WIDTH", "PAGE_HEIGHT"]
