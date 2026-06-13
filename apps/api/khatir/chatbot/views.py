"""Chatbot API — send a message + read history (EPIC-23.T-002 §3/§7).

``POST /api/v1/chat`` persists the user's turn, routes through the AI gateway
(chat category) with a user-scoped system prompt, persists the assistant reply
and returns it. ``GET /api/v1/chat/history`` lists the caller's messages,
newest-first and paginated.

Both surfaces are **owner-scoped** — every queryset filters on ``request.user``,
so a user only ever sees their own conversations/messages. The endpoint is
gated by the ``chatbot_enabled`` flag (kill-switch, default on): when disabled
it returns the standard ``feature_disabled`` 403 envelope before any gateway
call. Available to any authenticated user (landlord or tenant). Per-user
rate-limited because each message hits the paid AI gateway.
"""

from __future__ import annotations

from typing import Any, cast

from django.db.models import QuerySet
from rest_framework.generics import ListAPIView
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from khatir.accounts.models import User
from khatir.core.exceptions import FeatureDisabledError
from khatir.core.pagination import StandardPageNumberPagination
from khatir.core.permissions import IsAuthenticated
from khatir.core.responses import created

from .flags import is_chatbot_enabled
from .models import ChatMessage
from .serializers import ChatMessageInputSerializer, ChatMessageSerializer
from .services import send_message
from .throttling import ChatUserThrottle


class ChatView(APIView):
    """``POST /api/v1/chat`` — send a message, get the assistant's reply."""

    permission_classes = [IsAuthenticated]
    throttle_classes = [ChatUserThrottle]

    def post(self, request: Request, *args: Any, **kwargs: Any) -> Response:
        if not is_chatbot_enabled():
            raise FeatureDisabledError("The assistant is currently disabled.")

        serializer = ChatMessageInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        reply = send_message(
            cast(User, request.user),
            content=serializer.validated_data["content"],
            conversation_id=serializer.validated_data.get("conversation_id"),
        )
        return created(ChatMessageSerializer(reply).data)


class ChatHistoryView(ListAPIView[ChatMessage]):
    """``GET /api/v1/chat/history`` — the caller's chat messages, paginated.

    Scoped to ``request.user`` via the conversation FK; an optional
    ``?conversation_id=`` narrows to one conversation (still owner-scoped, so a
    foreign id simply yields an empty list — never a leak).
    """

    permission_classes = [IsAuthenticated]
    serializer_class = ChatMessageSerializer
    pagination_class = StandardPageNumberPagination

    def get_queryset(self) -> QuerySet[ChatMessage]:
        user = cast(User, self.request.user)
        qs = ChatMessage.objects.filter(conversation__user=user).order_by(
            "-created_at"
        )
        raw_id = self.request.query_params.get("conversation_id")
        if raw_id and raw_id.isdigit():
            qs = qs.filter(conversation_id=int(raw_id))
        return qs
