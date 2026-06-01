"""Smoke tests for the unauthenticated health and public-config endpoints."""

from rest_framework.test import APIClient


def test_healthz_returns_ok(api_client: APIClient) -> None:
    response = api_client.get("/healthz")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_config_public_returns_empty_envelope(api_client: APIClient) -> None:
    response = api_client.get("/api/v1/config/public")
    assert response.status_code == 200
    assert response.json() == {"flags": {}, "config": {}}
