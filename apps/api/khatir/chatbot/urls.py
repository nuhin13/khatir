"""Chatbot routes mounted under ``/api/v1/`` (EPIC-23.T-002 §7).

``POST /api/v1/chat`` (send a message) and ``GET /api/v1/chat/history``
(conversation history). No trailing slash, per
``04_coding_conventions.md`` §1. The history route is listed first so the
literal ``chat/history`` prefix is matched before the bare ``chat``.
"""

from __future__ import annotations

from django.urls import path

from .views import ChatHistoryView, ChatView

app_name = "chatbot"

urlpatterns = [
    path("chat/history", ChatHistoryView.as_view(), name="chat-history"),
    path("chat", ChatView.as_view(), name="chat"),
]
