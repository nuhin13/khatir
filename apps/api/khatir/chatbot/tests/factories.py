"""factory-boy factories for the chatbot domain.

factory-boy ships no type stubs, so its dynamic attributes are opaque to mypy;
the per-module override in ``pyproject.toml`` relaxes the untyped-call checks.
"""

from __future__ import annotations

import factory

from khatir.accounts.tests.factories import UserFactory
from khatir.chatbot.enums import ChatRole
from khatir.chatbot.models import ChatConversation, ChatMessage


class ChatConversationFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = ChatConversation

    user = factory.SubFactory(UserFactory)  # type: ignore[attr-defined]


class ChatMessageFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = ChatMessage

    conversation = factory.SubFactory(ChatConversationFactory)  # type: ignore[attr-defined]
    role = ChatRole.USER
    content = factory.Sequence(lambda n: f"Message {n}")  # type: ignore[attr-defined]
