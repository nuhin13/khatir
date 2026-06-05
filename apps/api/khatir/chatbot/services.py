"""Chat orchestration service (EPIC-23.T-002 §2).

``send_message`` is the single entry point the view calls. It:

1. Resolves (or creates) the user's :class:`ChatConversation` — strictly scoped
   to ``user``; a conversation id that belongs to someone else is treated as
   *not found* (never edited, never leaked).
2. Persists the inbound user :class:`ChatMessage`.
3. Builds the system prompt (:mod:`khatir.chatbot.prompts`) + the prior turns of
   the conversation and calls the AI gateway (``chat`` category, EPIC-14.T-007).
4. Persists the assistant reply and returns the saved row.

All AI traffic goes through :func:`khatir.ai_providers.client.call_gateway`; this
service never touches a vendor SDK and never logs message content. Persistence is
wrapped in a transaction so a conversation never has a user turn without its
matching assistant turn (or vice-versa) on the happy path.
"""

from __future__ import annotations

from typing import Any

from django.db import transaction

from khatir.accounts.models import User
from khatir.ai_providers.client import AIGatewayError, call_gateway
from khatir.ai_providers.enums import AICategory
from khatir.core.exceptions import NotFoundError, UpstreamUnavailableError

from .enums import ChatRole
from .models import ChatConversation, ChatMessage
from .prompts import build_system_prompt

#: How many prior turns of the conversation to replay to the gateway. Bounds the
#: token cost / prompt size; the assistant still has the full DB history for
#: ``GET /chat/history``, this only limits what is sent upstream per turn.
HISTORY_WINDOW = 20


def get_or_create_conversation(
    user: User, *, conversation_id: int | None = None
) -> ChatConversation:
    """Return the user's conversation, scoped to ``user``.

    With ``conversation_id`` set, the row must belong to ``user`` — otherwise a
    :class:`NotFoundError` is raised (a foreign/unknown id is invisible, never a
    leak). With no id, a fresh conversation is started for ``user``.
    """
    if conversation_id is not None:
        conversation = ChatConversation.objects.filter(
            pk=conversation_id, user=user
        ).first()
        if conversation is None:
            raise NotFoundError("Conversation not found.")
        return conversation
    return ChatConversation.objects.create(user=user)


def _gateway_messages(
    conversation: ChatConversation, *, limit: int = HISTORY_WINDOW
) -> list[dict[str, str]]:
    """Build the ``messages`` array for the gateway from stored turns.

    Takes the most recent ``limit`` turns (already including the just-saved user
    message) in chronological order, shaped as ``{"role", "content"}`` — the
    contract the gateway's chat provider expects.
    """
    recent = list(
        conversation.messages.order_by("-created_at").values("role", "content")[:limit]
    )
    recent.reverse()
    return [{"role": m["role"], "content": m["content"]} for m in recent]


def send_message(
    user: User, *, content: str, conversation_id: int | None = None
) -> ChatMessage:
    """Persist ``content`` as the user's turn, call the gateway, persist the reply.

    Returns the saved assistant :class:`ChatMessage`. Raises
    :class:`NotFoundError` for a foreign ``conversation_id`` and
    :class:`UpstreamUnavailableError` if the AI gateway is unreachable/errors.
    """
    conversation = get_or_create_conversation(user, conversation_id=conversation_id)

    # Persist the user's turn first so it is durable even if the upstream call
    # fails, and so the history window includes it for the gateway request.
    user_message = ChatMessage.objects.create(
        conversation=conversation, role=ChatRole.USER, content=content
    )

    payload: dict[str, Any] = {
        "system": build_system_prompt(user),
        "messages": _gateway_messages(conversation),
        "language": getattr(user, "language", "") or "bn",
    }

    try:
        result = call_gateway(AICategory.CHAT, payload)
    except AIGatewayError as exc:
        # The user turn stays persisted (so a retry continues the thread); surface
        # a clean 502 envelope. The user message is not orphaned — there is simply
        # no assistant reply yet.
        raise UpstreamUnavailableError(
            "The assistant is temporarily unavailable. Please try again."
        ) from exc

    reply_text = str(result.data.get("reply") or "").strip()

    with transaction.atomic():
        assistant_message = ChatMessage.objects.create(
            conversation=conversation,
            role=ChatRole.ASSISTANT,
            content=reply_text,
        )
    # Touch nothing else; the user turn is already saved.
    _ = user_message  # keep an explicit reference (persisted above)
    return assistant_message
