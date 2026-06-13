"""Tests for the EC verification provider abstraction — EPIC-17.T-002.

The vendor is mocked via an injected fake session (no real HTTP). Core
invariants asserted:

* matched / not_matched / error are normalized to a boolean-only outcome;
* the raw vendor payload is never surfaced on the returned DTO (only the match
  boolean + opaque ``provider_ref`` survive);
* a missing DPA reference blocks the call entirely (PDPA gate).
"""

from __future__ import annotations

import dataclasses

import pytest
import requests

from khatir.verification.enums import VerificationResult
from khatir.verification.providers import (
    ECVerificationProvider,
    VerificationOutcome,
    VerificationProvider,
    VerificationProviderError,
)


class _FakeResponse:
    def __init__(
        self, *, ok: bool = True, status_code: int = 200, json_body: object = None
    ) -> None:
        self.ok = ok
        self.status_code = status_code
        self._json_body = json_body
        self._raise_json = json_body is _NO_JSON

    def json(self) -> object:
        if self._raise_json:
            raise ValueError("no json")
        return self._json_body


_NO_JSON = object()


class _FakeSession:
    """Records the last request and returns a canned response (or raises)."""

    def __init__(self, response: object = None, *, exc: Exception | None = None) -> None:
        self._response = response
        self._exc = exc
        self.last_kwargs: dict[str, object] | None = None
        self.last_url: str | None = None

    def post(self, url: str, **kwargs: object) -> object:
        self.last_url = url
        self.last_kwargs = kwargs
        if self._exc is not None:
            raise self._exc
        return self._response


def _make_provider(session: _FakeSession) -> ECVerificationProvider:
    return ECVerificationProvider(
        endpoint_url="https://ec.example/verify",
        api_key="secret-key",
        dpa_ref="DPA-2026-001",
        session=session,
    )


def test_provider_implements_abc() -> None:
    assert issubclass(ECVerificationProvider, VerificationProvider)
    assert isinstance(_make_provider(_FakeSession()), VerificationProvider)


def test_matched() -> None:
    session = _FakeSession(
        _FakeResponse(json_body={"matched": True, "transaction_id": "tx-123"})
    )
    outcome = _make_provider(session).verify("1234567890", "Ada Lovelace", "1990-01-01")
    assert outcome.result == VerificationResult.MATCHED
    assert outcome.matched is True
    assert outcome.is_error is False
    assert outcome.provider_ref == "tx-123"


def test_not_matched() -> None:
    session = _FakeSession(
        _FakeResponse(json_body={"matched": False, "transaction_id": "tx-456"})
    )
    outcome = _make_provider(session).verify("1234567890", "Wrong Name", "1990-01-01")
    assert outcome.result == VerificationResult.NOT_MATCHED
    assert outcome.matched is False
    assert outcome.provider_ref == "tx-456"


def test_vendor_error_http_status() -> None:
    session = _FakeSession(_FakeResponse(ok=False, status_code=503))
    outcome = _make_provider(session).verify("1234567890", "Ada", "1990-01-01")
    assert outcome.result == VerificationResult.ERROR
    assert outcome.is_error is True
    assert "503" in outcome.error_detail


def test_vendor_transport_error() -> None:
    session = _FakeSession(exc=requests.ConnectionError("boom"))
    outcome = _make_provider(session).verify("1234567890", "Ada", "1990-01-01")
    assert outcome.result == VerificationResult.ERROR
    assert "transport error" in outcome.error_detail


def test_non_json_response_is_error() -> None:
    session = _FakeSession(_FakeResponse(json_body=_NO_JSON))
    outcome = _make_provider(session).verify("1234567890", "Ada", "1990-01-01")
    assert outcome.result == VerificationResult.ERROR


def test_missing_match_boolean_is_error() -> None:
    session = _FakeSession(_FakeResponse(json_body={"transaction_id": "tx-789"}))
    outcome = _make_provider(session).verify("1234567890", "Ada", "1990-01-01")
    assert outcome.result == VerificationResult.ERROR
    # Opaque ref still preserved for audit even on an error outcome.
    assert outcome.provider_ref == "tx-789"


def test_missing_dpa_ref_refuses_call() -> None:
    session = _FakeSession(_FakeResponse(json_body={"matched": True}))
    provider = ECVerificationProvider(
        endpoint_url="https://ec.example/verify",
        api_key="k",
        dpa_ref="",  # no DPA on file
        session=session,
    )
    with pytest.raises(VerificationProviderError):
        provider.verify("1234567890", "Ada", "1990-01-01")
    # No request must have been attempted.
    assert session.last_kwargs is None


def test_missing_endpoint_refuses_call() -> None:
    session = _FakeSession(_FakeResponse(json_body={"matched": True}))
    provider = ECVerificationProvider(
        endpoint_url="", api_key="k", dpa_ref="DPA-1", session=session
    )
    with pytest.raises(VerificationProviderError):
        provider.verify("1234567890", "Ada", "1990-01-01")


def test_request_carries_dpa_and_auth_but_outcome_has_no_raw_data() -> None:
    raw_leak = {
        "matched": True,
        "transaction_id": "tx-xyz",
        # vendor may echo PII; it must NOT appear on the outcome.
        "name": "Ada Lovelace",
        "dob": "1990-01-01",
        "address": "1 Analytical St",
        "photo": "base64...",
    }
    session = _FakeSession(_FakeResponse(json_body=raw_leak))
    outcome = _make_provider(session).verify("1234567890", "Ada Lovelace", "1990-01-01")

    # DPA ref + bearer token are sent to the vendor.
    assert session.last_kwargs is not None
    sent = session.last_kwargs["json"]
    assert isinstance(sent, dict)
    assert sent["dpa_ref"] == "DPA-2026-001"
    headers = session.last_kwargs["headers"]
    assert isinstance(headers, dict)
    assert headers["Authorization"] == "Bearer secret-key"

    # The outcome DTO exposes ONLY the boolean + opaque ref — no raw EC fields.
    outcome_fields = {f.name for f in dataclasses.fields(outcome)}
    assert outcome_fields == {"result", "provider_ref", "error_detail"}
    assert "Ada Lovelace" not in repr(outcome)
    assert "Analytical" not in repr(outcome)
    assert outcome.provider_ref == "tx-xyz"


def test_outcome_factory_helpers() -> None:
    assert VerificationOutcome.matched_result("r").result == VerificationResult.MATCHED
    assert (
        VerificationOutcome.not_matched_result("r").result
        == VerificationResult.NOT_MATCHED
    )
    err = VerificationOutcome.error_result("bad", "r")
    assert err.result == VerificationResult.ERROR
    assert err.error_detail == "bad"
