"""AI-providers domain enums — Domain 8 of ``06_database_schema.md``.

Domain-specific; used only by ``AIProvider`` and ``AIUsageLog``. Wire values
are lowercase snake_case strings matching ``docs/architecture/enums.md``.
"""

from django.db import models


class AICategory(models.TextChoices):
    """The capability category an AI provider is configured for.

    Wire values: ``chat`` · ``voice`` · ``ocr`` · ``lease`` (enums.md §AIProviderCategory).
    """

    CHAT = "chat", "Chat"
    VOICE = "voice", "Voice"
    OCR = "ocr", "OCR"
    LEASE = "lease", "Lease"
