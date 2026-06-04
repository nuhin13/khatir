"""Tests for the Django AI gateway client (EPIC-14.T-007 §12).

The gateway is mocked at the ``requests.post`` boundary so these tests are
hermetic and never open a socket.
"""

from __future__ import annotations

from typing import Any
from unittest import mock

import pytest
import requests

from khatir.ai_providers.client import (
    AIGatewayError,
    AIGatewayResult,
    call_gateway,
    extract_nid,
)
from khatir.ai_providers.enums import AICategory


class _FakeResponse:
    """Minimal stand-in for ``requests.Response`` used by the client."""

    def __init__(
        self,
        *,
        status_code: int = 200,
        json_body: Any = None,
        raise_json: bool = False,
    ) -> None:
        self.status_code = status_code
        self._json_body = json_body
        self._raise_json = raise_json

    @property
    def ok(self) -> bool:
        return 200 <= self.status_code < 300

    def json(self) -> Any:
        if self._raise_json:
            raise ValueError("not json")
        return self._json_body


GATEWAY_URL = "http://gateway.test:8100"
TOKEN = "secret-internal-token"  # noqa: S105 - test fixture, not a real secret


@pytest.fixture
def configured(settings: Any) -> None:
    settings.AI_GATEWAY_URL = GATEWAY_URL
    settings.AI_GATEWAY_INTERNAL_TOKEN = TOKEN
    settings.AI_GATEWAY_TIMEOUT = 5.0


# --- happy path --------------------------------------------------------------


def test_call_gateway_returns_normalised_result(configured: None) -> None:
    body = {
        "data": {"text": "hello"},
        "provider_key": "openai",
        "model_name": "gpt-4o",
    }
    with mock.patch(
        "khatir.ai_providers.client.requests.post",
        return_value=_FakeResponse(json_body=body),
    ) as post:
        result = call_gateway(AICategory.CHAT, {"prompt": "hi"})

    assert isinstance(result, AIGatewayResult)
    assert result.data == {"text": "hello"}
    assert result.provider_key == "openai"
    assert result.model_name == "gpt-4o"
    assert result.raw == body

    # URL, payload, token header and timeout are all forwarded.
    _, kwargs = post.call_args
    assert post.call_args.args[0] == f"{GATEWAY_URL}/v1/chat"
    assert kwargs["json"] == {"prompt": "hi"}
    assert kwargs["headers"]["Authorization"] == f"Bearer {TOKEN}"
    assert kwargs["timeout"] == 5.0


def test_call_gateway_accepts_string_category(configured: None) -> None:
    with mock.patch(
        "khatir.ai_providers.client.requests.post",
        return_value=_FakeResponse(json_body={"data": {}}),
    ) as post:
        call_gateway("ocr", {"image": "..."})
    assert post.call_args.args[0] == f"{GATEWAY_URL}/v1/ocr"


def test_call_gateway_explicit_timeout_overrides_setting(configured: None) -> None:
    with mock.patch(
        "khatir.ai_providers.client.requests.post",
        return_value=_FakeResponse(json_body={"data": {}}),
    ) as post:
        call_gateway(AICategory.VOICE, {}, timeout=1.5)
    assert post.call_args.kwargs["timeout"] == 1.5


# --- configuration -----------------------------------------------------------


def test_missing_url_raises_clear_config_error(settings: Any) -> None:
    settings.AI_GATEWAY_URL = ""
    with pytest.raises(AIGatewayError, match="AI_GATEWAY_URL is not configured"):
        call_gateway(AICategory.CHAT, {})


def test_no_auth_header_when_token_absent(settings: Any) -> None:
    settings.AI_GATEWAY_URL = GATEWAY_URL
    settings.AI_GATEWAY_INTERNAL_TOKEN = ""
    with mock.patch(
        "khatir.ai_providers.client.requests.post",
        return_value=_FakeResponse(json_body={"data": {}}),
    ) as post:
        call_gateway(AICategory.CHAT, {})
    assert "Authorization" not in post.call_args.kwargs["headers"]


# --- failure modes -----------------------------------------------------------


def test_transport_error_wrapped(configured: None) -> None:
    with mock.patch(
        "khatir.ai_providers.client.requests.post",
        side_effect=requests.ConnectionError("boom"),
    ):
        with pytest.raises(AIGatewayError, match="request failed") as exc:
            call_gateway(AICategory.CHAT, {})
    assert exc.value.status_code is None


def test_non_2xx_raises_with_status(configured: None) -> None:
    with mock.patch(
        "khatir.ai_providers.client.requests.post",
        return_value=_FakeResponse(status_code=502, json_body={}),
    ):
        with pytest.raises(AIGatewayError) as exc:
            call_gateway(AICategory.OCR, {})
    assert exc.value.status_code == 502


def test_non_json_body_raises(configured: None) -> None:
    with mock.patch(
        "khatir.ai_providers.client.requests.post",
        return_value=_FakeResponse(raise_json=True),
    ):
        with pytest.raises(AIGatewayError, match="non-JSON"):
            call_gateway(AICategory.CHAT, {})


def test_unexpected_shape_raises(configured: None) -> None:
    with mock.patch(
        "khatir.ai_providers.client.requests.post",
        return_value=_FakeResponse(json_body=["not", "a", "dict"]),
    ):
        with pytest.raises(AIGatewayError, match="unexpected response shape"):
            call_gateway(AICategory.CHAT, {})


# --- token is never logged ---------------------------------------------------


# --- extract_nid OCR helper (EPIC-14.T-008) ----------------------------------


def test_extract_nid_posts_base64_image_to_ocr(configured: None) -> None:
    import base64

    body = {"data": {"name": {"value": "Karim", "confidence": 0.9}}}
    with mock.patch(
        "khatir.ai_providers.client.requests.post",
        return_value=_FakeResponse(json_body=body),
    ) as post:
        result = extract_nid(b"\x89PNG-bytes")

    assert isinstance(result, AIGatewayResult)
    assert result.data == body["data"]
    assert post.call_args.args[0] == f"{GATEWAY_URL}/v1/ocr"
    sent = post.call_args.kwargs["json"]
    assert sent["image"] == base64.b64encode(b"\x89PNG-bytes").decode("ascii")


def test_token_not_in_exception_message(configured: None) -> None:
    with mock.patch(
        "khatir.ai_providers.client.requests.post",
        return_value=_FakeResponse(status_code=500, json_body={}),
    ):
        with pytest.raises(AIGatewayError) as exc:
            call_gateway(AICategory.CHAT, {})
    assert TOKEN not in str(exc.value)
