"""Chatbot domain models (EPIC-23 · T-001).

A ``ChatConversation`` is a single user's chat session with the assistant;
each ``ChatMessage`` is one turn within it, authored by the ``user`` or the
``assistant``. Conversations are owned by exactly one user (the FK is the
scoping boundary every chat endpoint and tool must filter on — a user only
ever sees their own conversations and messages).

The user FK is ``CASCADE`` (a conversation has no meaning once its owner is
gone) and the message → conversation FK is likewise ``CASCADE``. Both models
inherit ``TimeStampedModel`` for ``created_at`` / ``updated_at``;
``ChatConversation.started_at`` mirrors creation time but is stored explicitly
so it is queryable/orderable independently of the audit timestamps.

Indexes: ``ChatConversation(user, started_at)`` for "a user's conversations,
newest first"; ``ChatMessage(conversation, created_at)`` for replaying a
conversation in order.
"""

from __future__ import annotations

from django.conf import settings
from django.db import models
from django.utils import timezone

from khatir.core.models import TimeStampedModel

from .enums import ChatRole


class ChatConversation(TimeStampedModel):
    """A single user's chat session with the assistant."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="chat_conversations",
        help_text="Owner of the conversation. Scoping boundary for all chat access.",
    )
    started_at = models.DateTimeField(
        default=timezone.now,
        db_index=True,
        help_text="When the conversation began.",
    )

    class Meta:
        verbose_name = "chat conversation"
        verbose_name_plural = "chat conversations"
        ordering = ("-started_at",)
        indexes = [models.Index(fields=["user", "started_at"])]

    def __str__(self) -> str:
        return f"ChatConversation #{self.pk} — user {self.user_id}"


class ChatMessage(TimeStampedModel):
    """One turn in a ``ChatConversation``, authored by the user or assistant."""

    conversation = models.ForeignKey(
        ChatConversation,
        on_delete=models.CASCADE,
        related_name="messages",
        help_text="The conversation this message belongs to.",
    )
    role = models.CharField(
        max_length=16,
        choices=ChatRole.choices,
        help_text="Who authored the message: user or assistant.",
    )
    content = models.TextField(help_text="The message text.")

    class Meta:
        verbose_name = "chat message"
        verbose_name_plural = "chat messages"
        ordering = ("created_at",)
        indexes = [models.Index(fields=["conversation", "created_at"])]

    def __str__(self) -> str:
        return f"ChatMessage #{self.pk} — {self.role} in conversation {self.conversation_id}"
