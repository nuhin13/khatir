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

    @property
    def auth_enabled(self) -> bool:
        """Whether inbound calls must carry the internal token."""
        return bool(self.ai_gateway_internal_token)


@lru_cache
def get_settings() -> Settings:
    """Return a process-wide cached Settings instance."""
    return Settings()
