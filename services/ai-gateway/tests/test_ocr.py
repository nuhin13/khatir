"""OCR provider tests (mocked HTTP).

Exercises :class:`providers.ocr.GoogleVisionOcrProvider` end-to-end against an
``httpx.MockTransport`` so the network seam is fully mocked: request shaping
(base64 image, API key as query param — never in the body), response parsing
into the normalized :class:`ExtractedTenant` envelope, date/NID normalization,
and failure → :class:`ProviderError` (so the router can fail over).
"""

from __future__ import annotations

import base64
import json
from typing import Any

import httpx
import pytest

from providers.base import ProviderConfig, ProviderError
from providers.ocr import (
    GOOGLE_VISION_ENDPOINT,
    ExtractedTenant,
    GoogleVisionOcrProvider,
    build_ocr_provider,
)

IMAGE_BYTES = b"\x89PNG\r\n\x1a\nfake-nid-image"


def _config(*, api_key: str = "vision-secret", endpoint: str = "") -> ProviderConfig:
    return ProviderConfig(
        provider_key="google-vision",
        category="ocr",
        api_key=api_key,
        endpoint_url=endpoint,
    )


def _client(handler: Any) -> httpx.AsyncClient:
    return httpx.AsyncClient(transport=httpx.MockTransport(handler))


def _vision_response(text: str) -> dict[str, Any]:
    return {"responses": [{"fullTextAnnotation": {"text": text}}]}


async def _run(handler: Any, payload: dict[str, Any], **cfg: Any) -> Any:
    async with _client(handler) as client:
        provider = GoogleVisionOcrProvider(_config(**cfg), client)
        return await provider.call(payload)


async def test_default_endpoint_and_request_shape() -> None:
    captured: dict[str, Any] = {}

    def handler(request: httpx.Request) -> httpx.Response:
        captured["url"] = str(request.url)
        captured["body"] = json.loads(request.content)
        return httpx.Response(200, json=_vision_response("Name: Jamal Uddin"))

    result = await _run(handler, {"image": IMAGE_BYTES})

    # Defaults to the Google Vision endpoint when config leaves it blank.
    assert captured["url"].startswith(GOOGLE_VISION_ENDPOINT)
    # API key travels as a query param, never in the JSON body (self-review §14).
    assert "key=vision-secret" in captured["url"]
    assert "vision-secret" not in json.dumps(captured["body"])
    # Image is base64-encoded into the Vision request.
    content = captured["body"]["requests"][0]["image"]["content"]
    assert base64.b64decode(content) == IMAGE_BYTES
    assert captured["body"]["requests"][0]["features"][0]["type"] == "DOCUMENT_TEXT_DETECTION"
    assert result.data["name"]["value"] == "Jamal Uddin"


async def test_returns_extracted_tenant_json() -> None:
    text = "\n".join(
        [
            "Government of Bangladesh",
            "Name: Rahima Begum",
            "Date of Birth: 12/05/1988",
            "NID No: 1990 1234 5678",
            "Address: 14 Lake Road, Dhaka",
        ]
    )

    def handler(_request: httpx.Request) -> httpx.Response:
        return httpx.Response(200, json=_vision_response(text))

    result = await _run(handler, {"image": IMAGE_BYTES})

    data = result.data
    assert data["name"]["value"] == "Rahima Begum"
    assert data["nid_number"]["value"] == "199012345678"  # digits only
    assert data["dob"]["value"] == "1988-05-12"  # DD/MM/YYYY -> ISO
    assert data["address"]["value"] == "14 Lake Road, Dhaka"
    # Every DTO field is present even without confidence scores.
    assert set(data) == {"name", "nid_number", "dob", "address"}
    assert data["name"]["confidence"] is None


async def test_iso_date_passthrough() -> None:
    def handler(_request: httpx.Request) -> httpx.Response:
        return httpx.Response(200, json=_vision_response("DOB: 1995-11-03"))

    result = await _run(handler, {"image": IMAGE_BYTES})
    assert result.data["dob"]["value"] == "1995-11-03"


async def test_unreadable_image_returns_empty() -> None:
    def handler(_request: httpx.Request) -> httpx.Response:
        return httpx.Response(200, json={"responses": [{}]})

    result = await _run(handler, {"image": IMAGE_BYTES})
    assert result.data == ExtractedTenant().to_dict()
    assert all(result.data[f]["value"] is None for f in result.data)


async def test_accepts_base64_string_image() -> None:
    b64 = base64.b64encode(IMAGE_BYTES).decode("ascii")
    captured: dict[str, Any] = {}

    def handler(request: httpx.Request) -> httpx.Response:
        captured["body"] = json.loads(request.content)
        return httpx.Response(200, json=_vision_response("Name: X"))

    await _run(handler, {"image": b64})
    assert captured["body"]["requests"][0]["image"]["content"] == b64


async def test_missing_image_raises() -> None:
    def handler(_request: httpx.Request) -> httpx.Response:  # pragma: no cover
        return httpx.Response(200, json=_vision_response(""))

    with pytest.raises(ProviderError):
        await _run(handler, {})


async def test_http_error_raises_provider_error() -> None:
    def handler(_request: httpx.Request) -> httpx.Response:
        return httpx.Response(500, json={"error": "boom"})

    with pytest.raises(ProviderError) as exc:
        await _run(handler, {"image": IMAGE_BYTES})
    assert "HTTP 500" in str(exc.value)


async def test_vision_payload_error_raises() -> None:
    def handler(_request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            200, json={"responses": [{"error": {"message": "INVALID_IMAGE"}}]}
        )

    with pytest.raises(ProviderError) as exc:
        await _run(handler, {"image": IMAGE_BYTES})
    assert "INVALID_IMAGE" in str(exc.value)


async def test_legacy_text_annotations_shape() -> None:
    body = {"responses": [{"textAnnotations": [{"description": "Name: Legacy User"}]}]}

    def handler(_request: httpx.Request) -> httpx.Response:
        return httpx.Response(200, json=body)

    result = await _run(handler, {"image": IMAGE_BYTES})
    assert result.data["name"]["value"] == "Legacy User"


async def test_factory_builds_provider() -> None:
    async with _client(lambda r: httpx.Response(200, json={})) as client:
        provider = build_ocr_provider(_config(), client)
    assert isinstance(provider, GoogleVisionOcrProvider)
    assert provider.config.endpoint_url == GOOGLE_VISION_ENDPOINT


async def test_works_through_router() -> None:
    from providers.base import Provider
    from router import ProviderRouter

    calls = {"n": 0}

    def handler(_request: httpx.Request) -> httpx.Response:
        calls["n"] += 1
        return httpx.Response(200, json=_vision_response("Name: Routed User"))

    async with _client(handler) as client:

        async def source(_category: str) -> list[ProviderConfig]:
            return [
                ProviderConfig(
                    provider_key="google-vision",
                    category="ocr",
                    api_key="k",
                    is_primary=True,
                )
            ]

        def factory(config: ProviderConfig) -> Provider:
            return GoogleVisionOcrProvider(config, client)

        router = ProviderRouter(config_source=source, provider_factory=factory)
        result = await router.route("ocr", {"image": IMAGE_BYTES})

    assert calls["n"] == 1
    assert result.data["name"]["value"] == "Routed User"
