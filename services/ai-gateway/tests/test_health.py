"""Health endpoint and settings tests for the AI gateway scaffold."""

from __future__ import annotations

from fastapi.testclient import TestClient

from config import Settings
from main import create_app


def _client() -> TestClient:
    return TestClient(create_app(settings=Settings(ai_gateway_internal_token="")))


def test_healthz_returns_200() -> None:
    resp = _client().get("/healthz")
    assert resp.status_code == 200


def test_healthz_payload_shape() -> None:
    resp = _client().get("/healthz")
    body = resp.json()
    assert body["status"] == "ok"
    assert body["service"] == "khatir-ai-gateway"


def test_auth_disabled_when_token_blank() -> None:
    settings = Settings(ai_gateway_internal_token="")
    assert settings.auth_enabled is False


def test_auth_enabled_when_token_present() -> None:
    settings = Settings(ai_gateway_internal_token="s3cret")
    assert settings.auth_enabled is True


def test_default_port_is_8100() -> None:
    assert Settings(ai_gateway_internal_token="").port == 8100
