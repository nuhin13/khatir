"""User-scoped context summary for the chat system prompt (EPIC-23.T-002 §2).

The assistant may reference the user's **own** data ("what's my collection this
month?"). To keep that strictly scoped, the only data the model ever sees about
a user is the short, sanitised summary produced here from ``user`` — never a raw
queryset and never another user's records.

T-002 establishes the seam: a single :func:`build_user_context` that the chat
service injects into the system prompt. It is deliberately conservative — it
returns only identity-level facts (display name, role, language) that are
already the caller's own. The richer portfolio/rent summaries (own properties,
collection totals, …) are layered on by **T-003**, which owns the scoped data
tools; that task extends this function rather than the view, so scoping stays in
one auditable place (epic risk: "bot leaks another user's data").
"""

from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from khatir.accounts.models import User


def build_user_context(user: User) -> str:
    """Build the scoped, plain-text context block for ``user``.

    Only facts that belong to ``user`` are included; nothing here reaches across
    the ownership boundary. The output is a small, human-readable block embedded
    in the system prompt so the model can address the user correctly and stay
    grounded. Returns an empty string when there is nothing safe to add.
    """
    lines: list[str] = []
    name = (user.name or "").strip()
    if name:
        lines.append(f"User name: {name}")
    role = getattr(user, "role", "") or ""
    if role:
        lines.append(f"User role: {role}")
    language = getattr(user, "language", "") or ""
    if language:
        lines.append(f"Preferred language: {language}")
    return "\n".join(lines)
