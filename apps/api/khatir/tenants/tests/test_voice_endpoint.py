"""API tests for the Bangla voice endpoint (T-006 §12).

Drives ``POST /api/v1/tenants/voice`` through DRF's ``APIClient`` with the ASR
provider's single network seam (``DefaultAsrProvider._raw_extract``) mocked, so
no real provider is called. Covers: normalized fields returned (no ``photo_ref``
— voice has no stored artefact), the ``voice_tenant_entry`` flag gate (on by
default, 403 ``feature_disabled`` when off), role gating (landlord/manager only),
the per-user rate-limit, and that the audio is never echoed back.
"""

from __future__ import annotations

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
from khatir.featureflags.enums import FlagScope
from khatir.featureflags.tests.factories import FeatureFlagFactory

pytestmark = pytest.mark.django_db

VOICE_PATH = "/api/v1/tenants/voice"
RAW_EXTRACT = "khatir.tenants.extraction.asr_provider.DefaultAsrProvider._raw_extract"

# What the (mocked) ASR backend "hears" and parses from the clip.
RAW_ASR = {
    "name": "Karima Begum",
    "nid_number": "1985987654321",
    "dob": "1985-07-22",
    "address": "House 9, Khulna",
    "confidence": {"name": 0.95, "nid_number": 0.88},
}
AUDIO_BYTES = b"OggS\x00fake-bangla-audio"


@pytest.fixture
def landlord() -> User:
    created: User = UserFactory(  # type: ignore[assignment]
        phone="+8801712345678", name="Landlord", role=Role.LANDLORD
    )
    return created


@pytest.fixture
def client(landlord: User) -> APIClient:
    api = APIClient()
    api.force_authenticate(user=landlord)
    return api


def _upload() -> SimpleUploadedFile:
    return SimpleUploadedFile("clip.ogg", AUDIO_BYTES, content_type="audio/ogg")


def _post(client: APIClient) -> object:
    with mock.patch(RAW_EXTRACT, return_value=RAW_ASR):
        return client.post(VOICE_PATH, {"audio": _upload()}, format="multipart")


# --- fields returned ---------------------------------------------------------


def test_voice_returns_fields(client: APIClient) -> None:
    resp = _post(client)

    assert resp.status_code == status.HTTP_200_OK
    body = resp.json()
    assert body["name"] == {"value": "Karima Begum", "confidence": 0.95}
    assert body["nid_number"] == {"value": "1985987654321", "confidence": 0.88}
    assert body["dob"]["value"] == "1985-07-22"  # coerced to ISO date
    assert body["address"]["value"] == "House 9, Khulna"
    # No confidence reported for dob/address -> null, not absent.
    assert body["dob"]["confidence"] is None


def test_no_photo_ref_or_raw_payload(client: APIClient) -> None:
    resp = _post(client)

    body = resp.json()
    # Voice has no stored artefact: only the normalized field shape crosses the
    # boundary — no photo_ref, no provider-specific keys, no raw transcript.
    assert set(body) == {"name", "nid_number", "dob", "address"}
    # Raw audio bytes are never echoed in the response body.
    assert "fake-bangla-audio" not in resp.content.decode("latin-1")


# --- feature flag gate -------------------------------------------------------


def test_flag_on_by_default(client: APIClient) -> None:
    # No FeatureFlag row configured → default on (§10).
    assert _post(client).status_code == status.HTTP_200_OK


def test_flag_off_returns_403(client: APIClient) -> None:
    FeatureFlagFactory(
        key="voice_tenant_entry", scope=FlagScope.GLOBAL, enabled=False
    )

    resp = _post(client)
    assert resp.status_code == status.HTTP_403_FORBIDDEN
    assert resp.json()["error"]["code"] == "feature_disabled"


def test_flag_explicitly_on(client: APIClient) -> None:
    FeatureFlagFactory(
        key="voice_tenant_entry", scope=FlagScope.GLOBAL, enabled=True
    )
    assert _post(client).status_code == status.HTTP_200_OK


# --- permissions -------------------------------------------------------------


def test_requires_landlord(landlord: User) -> None:
    tenant_user = UserFactory(role=Role.TENANT)
    api = APIClient()
    api.force_authenticate(user=tenant_user)

    with mock.patch(RAW_EXTRACT, return_value=RAW_ASR):
        resp = api.post(VOICE_PATH, {"audio": _upload()}, format="multipart")

    assert resp.status_code == status.HTTP_403_FORBIDDEN


def test_manager_allowed(landlord: User) -> None:
    manager = UserFactory(role=Role.MANAGER)
    api = APIClient()
    api.force_authenticate(user=manager)

    with mock.patch(RAW_EXTRACT, return_value=RAW_ASR):
        resp = api.post(VOICE_PATH, {"audio": _upload()}, format="multipart")

    assert resp.status_code == status.HTTP_200_OK


def test_unauthenticated_rejected() -> None:
    resp = APIClient().post(VOICE_PATH, {"audio": _upload()}, format="multipart")
    assert resp.status_code in (
        status.HTTP_401_UNAUTHORIZED,
        status.HTTP_403_FORBIDDEN,
    )


def test_audio_required(client: APIClient) -> None:
    resp = client.post(VOICE_PATH, {}, format="multipart")
    assert resp.status_code == status.HTTP_400_BAD_REQUEST


# --- rate limit --------------------------------------------------------------


def _rest_with_rate(rate: str) -> dict[str, object]:
    return {
        **settings.REST_FRAMEWORK,
        "DEFAULT_THROTTLE_RATES": {
            **settings.REST_FRAMEWORK["DEFAULT_THROTTLE_RATES"],
            "tenant_voice": rate,
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
