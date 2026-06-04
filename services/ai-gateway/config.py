"""Runtime configuration for the AI gateway.

The gateway is a thin, stateless router. It holds no database and no business
logic; everything it needs comes from the environment. Provider credentials and
the Django-issued internal token are injected at deploy time via the shared
`.env` (see `.env.example` → "AI Gateway" block).
"""

from __future__ import annotations

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Environment-backed gateway settings.

    Field names map to env vars case-insensitively. The keys mirror the shared
    `.env.example` so the same file configures Django and the gateway.
    """

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
    )

    # Service identity / network.
    app_name: str = "khatir-ai-gateway"
    host: str = "0.0.0.0"  # noqa: S104 - bind all inside the container network
    port: int = 8100

    # Shared secret Django presents on every gateway call. Empty in local dev;
    # required (and enforced) in any deployment that sets it.
    ai_gateway_internal_token: str = ""

    # Where per-call usage is shipped after every provider call (T-006). The
    # gateway POSTs UsageRecords to `${django_base_url}${ai_usage_path}` with the
    # internal token as a bearer credential. When `django_base_url` is empty
    # (local dev / tests) usage logging falls back to a no-op so calls still
    # succeed without a Django backend.
    django_base_url: str = ""
    ai_usage_path: str = "/admin/api/ai-usage"
    ai_usage_timeout_seconds: float = 5.0

    @property
    def auth_enabled(self) -> bool:
        """Whether inbound calls must carry the internal token."""
        return bool(self.ai_gateway_internal_token)

    @property
    def usage_logging_enabled(self) -> bool:
        """Whether per-call usage should be POSTed to Django."""
        return bool(self.django_base_url)

    @property
    def ai_usage_url(self) -> str:
        """Absolute URL of Django's ai-usage ingest endpoint."""
        return f"{self.django_base_url.rstrip('/')}{self.ai_usage_path}"


@lru_cache
def get_settings() -> Settings:
    """Return a process-wide cached Settings instance."""
    return Settings()
