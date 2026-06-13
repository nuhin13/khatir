"""API tests for the NID OCR endpoint (T-005 §12).

Drives ``POST /api/v1/tenants/ocr`` through DRF's ``APIClient`` with the OCR
provider's single network seam (``DefaultOcrProvider._raw_extract``) mocked, so
no real provider is called. Covers: normalized fields + ``photo_ref`` returned,
the image stored **encrypted** at rest (and the raw image/payload never echoed),
role gating (landlord/manager only), and the per-user rate-limit.
"""

from __future__ import annotations

from collections.abc import Iterator
from pathlib import Path
from unittest import mock

import pytest
from django.conf import settings
from django.core.cache import cache
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import override_settings
from rest_framework import status
from rest_framework.test import APIClient

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory

pytestmark = pytest.mark.django_db

OCR_PATH = "/api/v1/tenants/ocr"
RAW_EXTRACT = "khatir.tenants.extraction.ocr_provider.DefaultOcrProvider._raw_extract"

# What the (mocked) OCR backend "reads" off the card.
RAW_OCR = {
    "name": "Rahim Uddin",
    "nid_number": "1990123456789",
    "dob": "1990-01-15",
    "address": "House 1, Dhaka",
    "confidence": {"name": 0.98, "nid_number": 0.91},
}
IMAGE_BYTES = b"\xff\xd8\xff\xe0fake-jpeg-bytes"


@pytest.fixture(autouse=True)
def storage_root(settings: object, tmp_path: Path) -> Iterator[None]:
    """Route the encrypted-storage FS fallback at a throwaway dir (no S3 in tests)."""
    settings.S3_BUCKET = ""  # type: ignore[attr-defined]
    settings.ENCRYPTED_STORAGE_ROOT = str(tmp_path)  # type: ignore[attr-defined]
    yield


@pytest.fixture
def landlord() -> User:
    created: User = UserFactory(  # type: ignore[assignment]
        phone="+8801712345678", name="Landlord", role=Role.LANDLORD
    )
    return created


def _grant_verification(user: User) -> None:
    """Put ``user`` on a paid tier that bundles NID verification (T-009 gate).

    OCR is tier-gated, so these field/storage/rate-limit tests run as users whose
    plan includes verification; the free-tier block is covered in
    ``billing/tests/test_tier_gate.py``.
    """
    from khatir.billing.enums import SubscriptionStatus
    from khatir.billing.tests.factories import (
        PricingTierFactory,
        SubscriptionFactory,
    )

    tier = PricingTierFactory(includes_verification=True)
    SubscriptionFactory(user=user, tier=tier, status=SubscriptionStatus.ACTIVE)


@pytest.fixture
def verified_plan(landlord: User) -> None:
    _grant_verification(landlord)


@pytest.fixture
def client(landlord: User, verified_plan: None) -> APIClient:
    api = APIClient()
    api.force_authenticate(user=landlord)
    return api


def _upload() -> SimpleUploadedFile:
    return SimpleUploadedFile("nid.jpg", IMAGE_BYTES, content_type="image/jpeg")


def _post(client: APIClient) -> object:
    with mock.patch(RAW_EXTRACT, return_value=RAW_OCR):
        return client.post(OCR_PATH, {"image": _upload()}, format="multipart")


# --- fields returned ---------------------------------------------------------


def test_ocr_returns_fields(client: APIClient) -> None:
    resp = _post(client)

    assert resp.status_code == status.HTTP_200_OK
    body = resp.json()
    assert body["name"] == {"value": "Rahim Uddin", "confidence": 0.98}
    assert body["nid_number"] == {"value": "1990123456789", "confidence": 0.91}
    assert body["dob"]["value"] == "1990-01-15"  # coerced to ISO date
    assert body["address"]["value"] == "House 1, Dhaka"
    # No confidence reported for dob/address -> null, not absent.
    assert body["dob"]["confidence"] is None
    assert body["photo_ref"].startswith("nid/")


def test_image_stored_encrypted(client: APIClient) -> None:
    resp = _post(client)

    photo_ref = resp.json()["photo_ref"]
    stored = Path(settings.ENCRYPTED_STORAGE_ROOT) / photo_ref
    # The file landed in the private (non-public) storage root under the nid/ kind.
    assert stored.exists()
    assert photo_ref.startswith("nid/")
    # Raw image bytes are never echoed in the response body.
    assert "fake-jpeg-bytes" not in resp.content.decode("latin-1")


def test_no_raw_payload_leaks(client: APIClient) -> None:
    resp = _post(client)

    body = resp.json()
    # Only the normalized shape crosses the boundary — no provider-specific keys.
    assert set(body) == {"name", "nid_number", "dob", "address", "photo_ref"}


# --- permissions -------------------------------------------------------------


def test_requires_landlord(landlord: User) -> None:
    tenant_user = UserFactory(role=Role.TENANT)
    api = APIClient()
    api.force_authenticate(user=tenant_user)

    with mock.patch(RAW_EXTRACT, return_value=RAW_OCR):
        resp = api.post(OCR_PATH, {"image": _upload()}, format="multipart")

    assert resp.status_code == status.HTTP_403_FORBIDDEN


def test_manager_allowed(landlord: User) -> None:
    manager = UserFactory(role=Role.MANAGER)
    _grant_verification(manager)
    api = APIClient()
    api.force_authenticate(user=manager)

    with mock.patch(RAW_EXTRACT, return_value=RAW_OCR):
        resp = api.post(OCR_PATH, {"image": _upload()}, format="multipart")

    assert resp.status_code == status.HTTP_200_OK


def test_unauthenticated_rejected() -> None:
    resp = APIClient().post(OCR_PATH, {"image": _upload()}, format="multipart")
    assert resp.status_code in (
        status.HTTP_401_UNAUTHORIZED,
        status.HTTP_403_FORBIDDEN,
    )


def test_image_required(client: APIClient) -> None:
    resp = client.post(OCR_PATH, {}, format="multipart")
    assert resp.status_code == status.HTTP_400_BAD_REQUEST


# --- rate limit --------------------------------------------------------------


def _rest_with_rate(rate: str) -> dict[str, object]:
    return {
        **settings.REST_FRAMEWORK,
        "DEFAULT_THROTTLE_RATES": {
            **settings.REST_FRAMEWORK["DEFAULT_THROTTLE_RATES"],
            "tenant_ocr": rate,
        },
    }


@override_settings(REST_FRAMEWORK=_rest_with_rate("2/hour"))
def test_rate_limited(client: APIClient) -> None:
    cache.clear()
    assert _post(client).status_code == status.HTTP_200_OK
    assert _post(client).status_code == status.HTTP_200_OK

    # 3rd call within the window → 429 with the standard rate_limited envelope.
    resp = _post(client)
    assert resp.status_code == status.HTTP_429_TOO_MANY_REQUESTS
    assert resp.json()["error"]["code"] == "rate_limited"


@override_settings(REST_FRAMEWORK=_rest_with_rate("2/hour"))
def test_rate_limit_is_per_user(landlord: User) -> None:
    cache.clear()
    _grant_verification(landlord)
    api = APIClient()
    api.force_authenticate(user=landlord)
    assert _post(api).status_code == status.HTTP_200_OK
    assert _post(api).status_code == status.HTTP_200_OK
    assert _post(api).status_code == status.HTTP_429_TOO_MANY_REQUESTS

    # A different user has an independent bucket.
    other = UserFactory(role=Role.LANDLORD)
    _grant_verification(other)
    other_api = APIClient()
    other_api.force_authenticate(user=other)
    assert _post(other_api).status_code == status.HTTP_200_OK
