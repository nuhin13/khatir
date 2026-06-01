"""Smoke tests for the unauthenticated health and public-config endpoints."""

import pytest
from rest_framework.test import APIClient

from khatir.core.models import SystemConfig


def test_healthz_returns_ok(api_client: APIClient) -> None:
    response = api_client.get("/healthz")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


@pytest.mark.django_db
def test_config_public_exposes_intro_slide_skip_allowed(api_client: APIClient) -> None:
    # Seeded by the 0002_seed_auth_config data migration.
    response = api_client.get("/api/v1/config/public")
    assert response.status_code == 200
    body = response.json()
    assert body["flags"] == {}
    assert body["config"]["intro_slide_skip_allowed"] is True


@pytest.mark.django_db
def test_config_public_reflects_db_override(api_client: APIClient) -> None:
    SystemConfig.objects.filter(key="intro_slide_skip_allowed").update(value="false")
    SystemConfig.objects.get(key="intro_slide_skip_allowed").save()  # invalidate cache
    response = api_client.get("/api/v1/config/public")
    assert response.status_code == 200
    assert response.json()["config"]["intro_slide_skip_allowed"] is False
