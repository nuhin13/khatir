"""User-scoped context summary for the chat system prompt (EPIC-23.T-002 §2).

The assistant may reference the user's **own** data ("what's my collection this
month?"). To keep that strictly scoped, the only data the model ever sees about
a user is the short, sanitised summary produced here from ``user`` — never a raw
queryset and never another user's records.

T-002 establishes the seam: a single :func:`build_user_context` that the chat
service injects into the system prompt. T-003 layers the richer portfolio/rent
summary (own collection / occupancy / overdue figures) onto that same function
via the scoped data tools in :mod:`khatir.chatbot.tools` — extending this
function rather than the view, so scoping stays in one auditable place (epic
risk: "bot leaks another user's data").
"""

from __future__ import annotations

from typing import TYPE_CHECKING

from .tools import format_portfolio_summary, get_portfolio_summary

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

    # T-003: append the user's own portfolio/rent summary. The tool is strictly
    # own-data (no user-id parameter) and returns an empty block when there is
    # nothing to report, so identity-only callers are unaffected.
    portfolio = format_portfolio_summary(get_portfolio_summary(user))
    if portfolio:
        lines.append(portfolio)
    return "\n".join(lines)
