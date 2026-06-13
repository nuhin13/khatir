"""Tests for the signed link-token service (EPIC-07 T-002 test plan).

Covers a valid round-trip (mint → resolve), expiry, and a tampered token. The
TTL is read from ``rent_link_token_ttl_hours`` config; expiry is simulated by
freezing the signer's clock via ``max_age`` on resolution.
"""

from __future__ import annotations

import time

import pytest

from khatir.core.exceptions import NotFoundError
from khatir.rent import tokens
from khatir.rent.models import RentRequest

from .factories import RentRequestFactory

pytestmark = pytest.mark.django_db


def test_valid_token_round_trips() -> None:
    req: RentRequest = RentRequestFactory()  # type: ignore[assignment]

    token = tokens.make_token(req)

    assert token
    req.refresh_from_db()
    assert req.link_token == token  # persisted on the request
    resolved = tokens.resolve_token(token)
    assert resolved.pk == req.pk


def test_one_token_one_request() -> None:
    a: RentRequest = RentRequestFactory()  # type: ignore[assignment]
    b: RentRequest = RentRequestFactory()  # type: ignore[assignment]

    token_a = tokens.make_token(a)
    token_b = tokens.make_token(b)

    assert token_a != token_b
    assert tokens.resolve_token(token_a).pk == a.pk
    assert tokens.resolve_token(token_b).pk == b.pk


def test_expired_token_rejected(monkeypatch: pytest.MonkeyPatch) -> None:
    req: RentRequest = RentRequestFactory()  # type: ignore[assignment]
    token = tokens.make_token(req)

    # Force the TTL to zero so any elapsed time is "expired".
    monkeypatch.setattr(tokens, "_ttl_seconds", lambda: 0)
    time.sleep(1)

    with pytest.raises(NotFoundError):
        tokens.resolve_token(token)


def test_tampered_token_rejected() -> None:
    req: RentRequest = RentRequestFactory()  # type: ignore[assignment]
    token = tokens.make_token(req)

    tampered = token[:-1] + ("a" if token[-1] != "a" else "b")

    with pytest.raises(NotFoundError):
        tokens.resolve_token(tampered)


def test_garbage_token_rejected() -> None:
    with pytest.raises(NotFoundError):
        tokens.resolve_token("not-a-real-token")


def test_unknown_request_rejected() -> None:
    req: RentRequest = RentRequestFactory()  # type: ignore[assignment]
    token = tokens.make_token(req)
    req.delete()

    with pytest.raises(NotFoundError):
        tokens.resolve_token(token)


# --- typed failure modes (EPIC-07 T-005 web page) ---------------------------
# The web pay page needs to tell "expired" (HTTP 410) apart from "invalid"
# (HTTP 404), so resolve_token raises the specific NotFoundError subclasses.


def test_resolve_expired_raises_expired_subclass(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    req: RentRequest = RentRequestFactory()  # type: ignore[assignment]
    token = tokens.make_token(req)
    monkeypatch.setattr(tokens, "_ttl_seconds", lambda: -1)

    with pytest.raises(tokens.ExpiredLinkToken):
        tokens.resolve_token(token)


def test_resolve_tampered_raises_invalid_subclass() -> None:
    req: RentRequest = RentRequestFactory()  # type: ignore[assignment]
    token = tokens.make_token(req)

    with pytest.raises(tokens.InvalidLinkToken):
        tokens.resolve_token(token + "x")


def test_resolve_garbage_raises_invalid_subclass() -> None:
    with pytest.raises(tokens.InvalidLinkToken):
        tokens.resolve_token("not-a-real-token")
