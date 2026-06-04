"""Khatir AI gateway — FastAPI entrypoint.

A thin, stateless router that all AI provider calls flow through (EPIC-14).
This scaffold (T-002) ships the service skeleton and the `/healthz` probe.
Provider routing endpoints are layered on by later tasks (T-003, T-007).
"""

from __future__ import annotations

from fastapi import FastAPI
from pydantic import BaseModel

from config import Settings, get_settings


class HealthResponse(BaseModel):
    """Liveness probe payload."""

    status: str
    service: str


def create_app(settings: Settings | None = None) -> FastAPI:
    """Application factory.

    Accepting an explicit `settings` lets tests inject a configuration without
    mutating the process environment.
    """
    settings = settings or get_settings()
    app = FastAPI(
        title="Khatir AI Gateway",
        version="0.1.0",
        description="Thin router for AI provider calls. No DB, no business logic.",
    )

    @app.get("/healthz", response_model=HealthResponse, tags=["health"])
    def healthz() -> HealthResponse:
        """Liveness check used by compose / orchestrator probes."""
        return HealthResponse(status="ok", service=settings.app_name)

    return app


app = create_app()
