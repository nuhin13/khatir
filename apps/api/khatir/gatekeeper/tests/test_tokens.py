"""Tests for the building-scoped visitor link-token service (T-004)."""

from __future__ import annotations

import pytest

from khatir.gatekeeper import tokens
from khatir.gatekeeper.tokens import (
    ExpiredVisitorToken,
    InvalidVisitorToken,
    make_token,
    resolve_token,
)
from khatir.properties.models import Building
from khatir.properties.tests.factories import BuildingFactory


@pytest.mark.django_db
def test_round_trip_resolves_building() -> None:
    building: Building = BuildingFactory()  # type: ignore[assignment]
    token = make_token(building)
    assert resolve_token(token).pk == building.pk


@pytest.mark.django_db
def test_token_is_building_scoped() -> None:
    a: Building = BuildingFactory()  # type: ignore[assignment]
    b: Building = BuildingFactory()  # type: ignore[assignment]
    token_a = make_token(a)
    token_b = make_token(b)
    assert token_a != token_b
    assert resolve_token(token_a).pk == a.pk
    assert resolve_token(token_b).pk == b.pk


@pytest.mark.django_db
def test_expired_token_raises_expired(monkeypatch: pytest.MonkeyPatch) -> None:
    building: Building = BuildingFactory()  # type: ignore[assignment]
    token = make_token(building)
    monkeypatch.setattr(tokens, "_ttl_seconds", lambda: -1)
    with pytest.raises(ExpiredVisitorToken):
        resolve_token(token)


@pytest.mark.django_db
def test_tampered_token_raises_invalid() -> None:
    building: Building = BuildingFactory()  # type: ignore[assignment]
    token = make_token(building)
    with pytest.raises(InvalidVisitorToken):
        resolve_token(token + "x")


@pytest.mark.django_db
def test_garbage_token_raises_invalid() -> None:
    with pytest.raises(InvalidVisitorToken):
        resolve_token("not-a-real-token")


@pytest.mark.django_db
def test_token_for_deleted_building_raises_invalid() -> None:
    building: Building = BuildingFactory()  # type: ignore[assignment]
    token = make_token(building)
    building.delete()
    with pytest.raises(InvalidVisitorToken):
        resolve_token(token)
