"""Tests for the token-scoped web pay page (T-005)."""

from __future__ import annotations

import pytest
from django.test import Client

from khatir.rent import tokens
from khatir.rent.models import RentRequest
from khatir.rent.tests.factories import RentRequestFactory


@pytest.mark.django_db
def test_valid_token_renders(client: Client) -> None:
    rr: RentRequest = RentRequestFactory(amount="26000.00", period="2026-05")  # type: ignore[assignment]
    rr.lease.unit.label = "4B"
    rr.lease.unit.save()
    rr.lease.landlord.name = "Abdul Karim"
    rr.lease.landlord.save()
    token = tokens.make_token(rr)

    resp = client.get(f"/r/{token}")
    assert resp.status_code == 200

    body = resp.content.decode()
    # Amount rendered in Bangla numerals (26,000 -> ২৬,০০০).
    assert "৳২৬,০০০" in body
    # Period label, unit, landlord all present.
    assert "মে ২০২৬" in body
    assert "4B" in body
    assert "Abdul Karim" in body
    # Proof form is server-rendered.
    assert "<form" in body
    assert 'name="txn_id"' in body


@pytest.mark.django_db
def test_expired_token_shows_error(
    client: Client, monkeypatch: pytest.MonkeyPatch
) -> None:
    rr: RentRequest = RentRequestFactory()  # type: ignore[assignment]
    token = tokens.make_token(rr)
    monkeypatch.setattr(tokens, "_ttl_seconds", lambda: -1)

    resp = client.get(f"/r/{token}")
    assert resp.status_code == 410
    assert "মেয়াদ শেষ" in resp.content.decode()


@pytest.mark.django_db
def test_invalid_token_shows_error(client: Client) -> None:
    resp = client.get("/r/not-a-real-token")
    assert resp.status_code == 404
    body = resp.content.decode()
    assert "খুঁজে পাওয়া যায়নি" in body


@pytest.mark.django_db
def test_page_uses_token_palette_not_hardcoded(client: Client) -> None:
    rr: RentRequest = RentRequestFactory()  # type: ignore[assignment]
    token = tokens.make_token(rr)
    resp = client.get(f"/r/{token}")
    body = resp.content.decode()
    # Notun Din palette is exposed as CSS custom properties and consumed via
    # var(...) — colours are token-sourced, not scattered prototype hex.
    assert "--rose-dk" in body
    assert "var(--rose-dk)" in body
