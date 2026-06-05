"""DRF serializers for the chat endpoint (EPIC-23.T-002 §3/§7).

``ChatMessageInputSerializer`` validates the inbound ``POST /chat`` body
(message text + optional conversation id). ``ChatMessageSerializer`` shapes a
stored :class:`~khatir.chatbot.models.ChatMessage` for both the POST reply and
the ``GET /chat/history`` listing.
"""

from __future__ import annotations

from rest_framework import serializers

from .models import ChatMessage

#: Cap the inbound message size — a chat turn is a question, not a document.
MAX_MESSAGE_LENGTH = 4000


class ChatMessageInputSerializer(serializers.Serializer[None]):
    """Validate the inbound chat request body."""

    content = serializers.CharField(
        max_length=MAX_MESSAGE_LENGTH,
        trim_whitespace=True,
        allow_blank=False,
        help_text="The user's message to the assistant.",
    )
    conversation_id = serializers.IntegerField(
        required=False,
        allow_null=True,
        min_value=1,
        help_text="Continue an existing conversation; omit to start a new one.",
    )


class ChatMessageSerializer(serializers.ModelSerializer[ChatMessage]):
    """Read-only shape of a stored chat message."""

    conversation_id = serializers.IntegerField(read_only=True)

    class Meta:
        model = ChatMessage
        fields = ("id", "conversation_id", "role", "content", "created_at")
        read_only_fields = fields
