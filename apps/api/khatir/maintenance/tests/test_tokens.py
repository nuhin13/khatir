"""Tests for the signed maintenance web-link token service (EPIC-08 T-004).

Covers a valid round-trip (mint → resolve), expiry, and a tampered token. The
token is unit-scoped and stateless (nothing persisted). The TTL is read from
``maintenance_link_token_ttl_hours`` config; expiry is simulated by shrinking
the TTL the signer enforces via ``max_age`` on resolution.
"""

from __future__ import annotations

import time

import pytest

from khatir.core.exceptions import NotFoundError
from khatir.maintenance import tokens
from khatir.properties.models import Unit
from khatir.properties.tests.factories import UnitFactory

pytestmark = pytest.mark.django_db


def test_valid_token_round_trips() -> None:
    unit: Unit = UnitFactory()  # type: ignore[assignment]

    token = tokens.make_token(unit)

    assert token
    resolved = tokens.resolve_token(token)
    assert resolved.pk == unit.pk


def test_token_is_unit_scoped() -> None:
    a: Unit = UnitFactory()  # type: ignore[assignment]
    b: Unit = UnitFactory()  # type: ignore[assignment]

    token_a = tokens.make_token(a)
    token_b = tokens.make_token(b)

    assert token_a != token_b
    assert tokens.resolve_token(token_a).pk == a.pk
    assert tokens.resolve_token(token_b).pk == b.pk


def test_expired_token_rejected(monkeypatch: pytest.MonkeyPatch) -> None:
    unit: Unit = UnitFactory()  # type: ignore[assignment]
    token = tokens.make_token(unit)

    # Force the TTL to zero so any elapsed time is "expired".
    monkeypatch.setattr(tokens, "_ttl_seconds", lambda: 0)
    time.sleep(1)

    with pytest.raises(NotFoundError):
        tokens.resolve_token(token)


def test_tampered_token_rejected() -> None:
    unit: Unit = UnitFactory()  # type: ignore[assignment]
    token = tokens.make_token(unit)

    tampered = token[:-1] + ("a" if token[-1] != "a" else "b")

    with pytest.raises(NotFoundError):
        tokens.resolve_token(tampered)


def test_garbage_token_rejected() -> None:
    with pytest.raises(NotFoundError):
        tokens.resolve_token("not-a-real-token")


def test_unknown_unit_rejected() -> None:
    unit: Unit = UnitFactory()  # type: ignore[assignment]
    token = tokens.make_token(unit)
    unit.delete()  # soft delete -> excluded from default manager

    with pytest.raises(NotFoundError):
        tokens.resolve_token(token)


# --- typed failure modes (EPIC-08 T-005 web form) ---------------------------
# The web form needs to tell "expired" (HTTP 410) apart from "invalid"
# (HTTP 404), so resolve_token raises the specific NotFoundError subclasses.


def test_resolve_expired_raises_expired_subclass(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    unit: Unit = UnitFactory()  # type: ignore[assignment]
    token = tokens.make_token(unit)
    monkeypatch.setattr(tokens, "_ttl_seconds", lambda: -1)

    with pytest.raises(tokens.ExpiredMaintenanceToken):
        tokens.resolve_token(token)


def test_resolve_tampered_raises_invalid_subclass() -> None:
    unit: Unit = UnitFactory()  # type: ignore[assignment]
    token = tokens.make_token(unit)

    with pytest.raises(tokens.InvalidMaintenanceToken):
        tokens.resolve_token(token + "x")


def test_resolve_garbage_raises_invalid_subclass() -> None:
    with pytest.raises(tokens.InvalidMaintenanceToken):
        tokens.resolve_token("not-a-real-token")


def test_maintenance_token_not_resolvable_as_rent_token() -> None:
    """A maintenance token uses a distinct salt; rent's resolver must reject it."""
    from khatir.rent import tokens as rent_tokens

    unit: Unit = UnitFactory()  # type: ignore[assignment]
    token = tokens.make_token(unit)

    with pytest.raises(NotFoundError):
        rent_tokens.resolve_token(token)
