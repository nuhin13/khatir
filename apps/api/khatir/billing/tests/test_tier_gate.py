"""NID verification tier-gate tests (EPIC-10 T-009 §12).

Exercises ``check_can_verify`` and its wiring into the NID OCR + voice endpoints:

* a free-tier user (no active subscription) is blocked with the
  ``feature_requires_upgrade`` / ``402`` envelope;
* a paid tier whose ``includes_verification`` is false is still blocked;
* a paid tier that bundles verification (e.g. ``bundle_10``) passes;
* a cancelled verification plan falls back to the free (gated) behaviour;
* the gate runs at the endpoint before any image is stored or any paid provider
  is called, so a free-tier landlord hitting OCR/voice gets the upgrade envelope.

Manual tenant entry is intentionally *not* gated — that path is covered by the
metering tests (``test_metering.py``); here we only assert the verification gate.
"""

from __future__ import annotations

from collections.abc import Iterator
from pathlib import Path
from unittest import mock

import pytest
from django.core.files.uploadedfile import SimpleUploadedFile
from rest_framework import status
from rest_framework.test import APIClient

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.billing.enums import SubscriptionStatus
from khatir.billing.services import check_can_verify
from khatir.billing.tests.factories import PricingTierFactory, SubscriptionFactory
from khatir.core.enums import ErrorCode
from khatir.core.exceptions import TierFeatureGated

pytestmark = pytest.mark.django_db

OCR_PATH = "/api/v1/tenants/ocr"
VOICE_PATH = "/api/v1/tenants/voice"
OCR_RAW_EXTRACT = (
    "khatir.tenants.extraction.ocr_provider.DefaultOcrProvider._raw_extract"
)
VOICE_RAW_EXTRACT = (
    "khatir.tenants.extraction.asr_provider.DefaultAsrProvider._raw_extract"
)
RAW_OCR = {"name": "Rahim Uddin", "nid_number": "1990123456789"}
RAW_ASR = {"name": "Karima Begum", "nid_number": "1985987654321"}


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


@pytest.fixture
def client(landlord: User) -> APIClient:
    api = APIClient()
    api.force_authenticate(user=landlord)
    return api


def _subscribe(user: User, *, includes_verification: bool, **kwargs: object) -> None:
    tier = PricingTierFactory(includes_verification=includes_verification)
    SubscriptionFactory(
        user=user,
        tier=tier,
        status=kwargs.get("status", SubscriptionStatus.ACTIVE),
    )


# --- service -----------------------------------------------------------------


def test_free_tier_blocked(landlord: User) -> None:
    """No active subscription => verification is not included => blocked."""
    with pytest.raises(TierFeatureGated) as exc:
        check_can_verify(landlord)

    assert exc.value.error_code == ErrorCode.FEATURE_REQUIRES_UPGRADE
    assert exc.value.status_code == status.HTTP_402_PAYMENT_REQUIRED


def test_paid_without_verification_blocked(landlord: User) -> None:
    _subscribe(landlord, includes_verification=False)

    with pytest.raises(TierFeatureGated):
        check_can_verify(landlord)


def test_bundle_with_verification_ok(landlord: User) -> None:
    _subscribe(landlord, includes_verification=True)

    # No exception => verification allowed.
    check_can_verify(landlord)


def test_cancelled_verification_plan_falls_back_to_blocked(landlord: User) -> None:
    tier = PricingTierFactory(includes_verification=True)
    SubscriptionFactory(
        user=landlord, tier=tier, status=SubscriptionStatus.CANCELLED
    )

    with pytest.raises(TierFeatureGated):
        check_can_verify(landlord)


# --- wiring: OCR endpoint ----------------------------------------------------


def _post_ocr(client: APIClient) -> object:
    upload = SimpleUploadedFile("nid.jpg", b"\xff\xd8\xfffake", content_type="image/jpeg")
    with mock.patch(OCR_RAW_EXTRACT, return_value=RAW_OCR):
        return client.post(OCR_PATH, {"image": upload}, format="multipart")


def test_ocr_blocked_free(client: APIClient) -> None:
    resp = _post_ocr(client)

    assert resp.status_code == status.HTTP_402_PAYMENT_REQUIRED  # type: ignore[attr-defined]
    body = resp.json()  # type: ignore[attr-defined]
    assert body["error"]["code"] == ErrorCode.FEATURE_REQUIRES_UPGRADE.value


def test_ocr_ok_bundle10(client: APIClient, landlord: User) -> None:
    _subscribe(landlord, includes_verification=True)

    resp = _post_ocr(client)
    assert resp.status_code == status.HTTP_200_OK  # type: ignore[attr-defined]


def test_ocr_gate_runs_before_storage(client: APIClient) -> None:
    """A free-tier OCR call is rejected before any image is stored at rest."""
    with mock.patch(
        "khatir.tenants.views.store_encrypted"
    ) as store, mock.patch(OCR_RAW_EXTRACT, return_value=RAW_OCR):
        resp = client.post(
            OCR_PATH,
            {"image": SimpleUploadedFile("n.jpg", b"x", content_type="image/jpeg")},
            format="multipart",
        )

    assert resp.status_code == status.HTTP_402_PAYMENT_REQUIRED
    store.assert_not_called()


# --- wiring: voice endpoint --------------------------------------------------


def _post_voice(client: APIClient) -> object:
    upload = SimpleUploadedFile("clip.ogg", b"OggSfake", content_type="audio/ogg")
    with mock.patch(VOICE_RAW_EXTRACT, return_value=RAW_ASR):
        return client.post(VOICE_PATH, {"audio": upload}, format="multipart")


def test_voice_blocked_free(client: APIClient) -> None:
    resp = _post_voice(client)

    assert resp.status_code == status.HTTP_402_PAYMENT_REQUIRED  # type: ignore[attr-defined]
    body = resp.json()  # type: ignore[attr-defined]
    assert body["error"]["code"] == ErrorCode.FEATURE_REQUIRES_UPGRADE.value


def test_voice_ok_bundle10(client: APIClient, landlord: User) -> None:
    _subscribe(landlord, includes_verification=True)

    resp = _post_voice(client)
    assert resp.status_code == status.HTTP_200_OK  # type: ignore[attr-defined]
