"""Tests for the server-rendered visitor sign-in *page* (``GET /v/<token>``, T-005).

The matching submit handler (``POST /v/<token>/submit``) is covered by
``test_web_visitor.py`` (T-004); here we cover the bilingual form render, the
submitted-success state, and the invalid/expired/flag-off error surfaces.
"""

from __future__ import annotations

import pytest
from django.test import Client

from khatir.featureflags.enums import FlagScope
from khatir.featureflags.models import FeatureFlag
from khatir.gatekeeper import tokens
from khatir.gatekeeper.flags import GATEKEEPER_ENABLED
from khatir.properties.models import Building
from khatir.properties.tests.factories import BuildingFactory


@pytest.mark.django_db
def test_visitor_form_renders(client: Client) -> None:
    building: Building = BuildingFactory(name="Karim Manzil")  # type: ignore[assignment]
    token = tokens.make_token(building)

    resp = client.get(f"/v/{token}")

    assert resp.status_code == 200
    body = resp.content.decode()
    # Bilingual hero + the building name from the token-resolved building.
    assert "Welcome, visitor" in body
    assert "অতিথি তথ্য দিন" in body
    assert "Karim Manzil" in body
    # The form posts to the T-004 submit endpoint with the visitor_name field.
    assert f'action="/v/{token}/submit"' in body
    assert 'name="visitor_name"' in body
    # Privacy notice for the optional selfie is shown.
    assert "auto-deleted" in body
    assert 'name="photo"' in body


@pytest.mark.django_db
def test_visitor_form_submitted_state(client: Client) -> None:
    building: Building = BuildingFactory()  # type: ignore[assignment]
    token = tokens.make_token(building)

    resp = client.get(f"/v/{token}?submitted=1")

    assert resp.status_code == 200
    body = resp.content.decode()
    assert "review and let you in" in body
    # The blank form is not shown in the success state.
    assert 'name="visitor_name"' not in body


@pytest.mark.django_db
def test_visitor_form_invalid_token_404(client: Client) -> None:
    resp = client.get("/v/not-a-real-token")

    assert resp.status_code == 404
    assert "invalid or no longer exists" in resp.content.decode()


@pytest.mark.django_db
def test_visitor_form_expired_token_410(
    client: Client, monkeypatch: pytest.MonkeyPatch
) -> None:
    building: Building = BuildingFactory()  # type: ignore[assignment]
    token = tokens.make_token(building)
    monkeypatch.setattr(tokens, "_ttl_seconds", lambda: -1)

    resp = client.get(f"/v/{token}")

    assert resp.status_code == 410
    assert "has expired" in resp.content.decode()


@pytest.mark.django_db
def test_visitor_form_rejects_post(client: Client) -> None:
    building: Building = BuildingFactory()  # type: ignore[assignment]
    token = tokens.make_token(building)

    resp = client.post(f"/v/{token}")

    # The page is GET-only; submissions go to ``/v/<token>/submit``.
    assert resp.status_code == 405


@pytest.mark.django_db
def test_visitor_form_blocked_when_flag_disabled(client: Client) -> None:
    building: Building = BuildingFactory()  # type: ignore[assignment]
    token = tokens.make_token(building)
    FeatureFlag.objects.create(
        key=GATEKEEPER_ENABLED, scope=FlagScope.GLOBAL, enabled=False
    )

    resp = client.get(f"/v/{token}")

    # Feature off behaves like an unknown link — never reveal the page exists.
    assert resp.status_code == 404
    assert "invalid or no longer exists" in resp.content.decode()
