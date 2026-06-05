"""Chatbot-domain enums (EPIC-23).

Domain-specific (used only by ``ChatMessage``), so they live in the owning app
rather than ``khatir.core.enums``. Wire values are lowercase snake_case strings,
never integers.
"""

from django.db import models


class ChatRole(models.TextChoices):
    """Author of a chat message."""

    USER = "user", "User"
    ASSISTANT = "assistant", "Assistant"
