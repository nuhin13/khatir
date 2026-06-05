"""Tests for ``ChatConversation`` and ``ChatMessage`` models (T-001 §12)."""

from __future__ import annotations

import pytest

from khatir.chatbot.enums import ChatRole
from khatir.chatbot.models import ChatConversation, ChatMessage

from .factories import ChatConversationFactory, ChatMessageFactory

pytestmark = pytest.mark.django_db


# --- ChatConversation -------------------------------------------------------


def test_conversation_create() -> None:
    convo: ChatConversation = ChatConversationFactory()  # type: ignore[assignment]
    assert convo.pk is not None
    assert convo.user_id is not None
    assert convo.started_at is not None
    assert convo.created_at is not None
    assert str(convo) == f"ChatConversation #{convo.pk} — user {convo.user_id}"


def test_conversation_started_at_defaults_on_create() -> None:
    convo: ChatConversation = ChatConversationFactory()  # type: ignore[assignment]
    convo.refresh_from_db()
    assert convo.started_at is not None


def test_conversation_messages_related_name() -> None:
    convo: ChatConversation = ChatConversationFactory()  # type: ignore[assignment]
    ChatMessageFactory(conversation=convo, role=ChatRole.USER)
    ChatMessageFactory(conversation=convo, role=ChatRole.ASSISTANT)
    assert convo.messages.count() == 2


def test_conversation_scoped_to_one_user() -> None:
    a: ChatConversation = ChatConversationFactory()  # type: ignore[assignment]
    b: ChatConversation = ChatConversationFactory()  # type: ignore[assignment]
    assert a.user_id != b.user_id
    assert ChatConversation.objects.filter(user_id=a.user_id).count() == 1


# --- ChatMessage ------------------------------------------------------------


def test_message_create_user_role() -> None:
    msg: ChatMessage = ChatMessageFactory(  # type: ignore[assignment]
        role=ChatRole.USER, content="What is my rent due date?"
    )
    assert msg.pk is not None
    assert msg.conversation_id is not None
    assert msg.role == ChatRole.USER
    assert msg.content == "What is my rent due date?"
    assert str(msg) == (
        f"ChatMessage #{msg.pk} — user in conversation {msg.conversation_id}"
    )


def test_message_create_assistant_role() -> None:
    msg: ChatMessage = ChatMessageFactory(  # type: ignore[assignment]
        role=ChatRole.ASSISTANT, content="Your rent is due on the 1st."
    )
    assert msg.role == ChatRole.ASSISTANT


def test_messages_ordered_by_created_at() -> None:
    convo: ChatConversation = ChatConversationFactory()  # type: ignore[assignment]
    first = ChatMessageFactory(conversation=convo, role=ChatRole.USER)
    second = ChatMessageFactory(conversation=convo, role=ChatRole.ASSISTANT)
    ordered = list(convo.messages.all())
    assert ordered == [first, second]


def test_message_cascade_deletes_with_conversation() -> None:
    convo: ChatConversation = ChatConversationFactory()  # type: ignore[assignment]
    ChatMessageFactory(conversation=convo)
    convo_pk = convo.pk
    convo.delete()
    assert not ChatMessage.objects.filter(conversation_id=convo_pk).exists()


def test_role_choices_are_user_and_assistant() -> None:
    assert ChatRole.USER == "user"
    assert ChatRole.ASSISTANT == "assistant"
    assert set(ChatRole.values) == {"user", "assistant"}
