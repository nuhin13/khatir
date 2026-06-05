"""System-prompt assembly for the chatbot (EPIC-23.T-002 §2).

The system prompt frames the assistant's role, its scope boundaries, and embeds
the caller's user-scoped context (:mod:`khatir.chatbot.context`). T-002 ships a
grounded baseline; the full guardrails + disclaimers (refuse legal/financial
advice, etc.) are hardened by **T-004**, which extends :data:`BASE_SYSTEM_PROMPT`
rather than the view so the safety rules live in one auditable place.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

from .context import build_user_context

if TYPE_CHECKING:
    from khatir.accounts.models import User

#: Baseline framing for the in-app assistant. Bilingual (Bangla/English) product
#: + tenancy helper, scoped to the user's own data, read-only (no actions).
BASE_SYSTEM_PROMPT = (
    "You are Khatir's in-app assistant for landlords and tenants in Bangladesh. "
    "Answer product and tenancy questions clearly in the user's language "
    "(Bangla or English). You may reference ONLY the user's own data that is "
    "provided in the context block below; never invent or reference any other "
    "user's information. You provide read-only guidance and cannot perform "
    "actions, move money, or change records. Do not give definitive legal or "
    "financial advice; for those, recommend consulting a qualified professional."
)


def build_system_prompt(user: User) -> str:
    """Assemble the full system prompt for ``user``.

    Combines the baseline framing with the user's scoped context block. When the
    context is empty (nothing safe to add) only the baseline is returned.
    """
    context = build_user_context(user)
    if not context:
        return BASE_SYSTEM_PROMPT
    return f"{BASE_SYSTEM_PROMPT}\n\n--- User context (the user's OWN data) ---\n{context}"
