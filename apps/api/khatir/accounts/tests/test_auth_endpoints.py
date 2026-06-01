"""API tests for the OTP auth endpoints (T-005 §12).

Exercises ``request-otp`` (happy / invalid phone / cooldown) and ``verify-otp``
(happy → creates user / wrong code / expired code) through DRF's ``APIClient``,
hitting the real services + OTP store (LocMem cache from ``settings.test``,
cleared between tests by the OTP store's own TTLs). The notification *sender* is
mocked so no real WhatsApp/SMS/console dispatch happens, per the task brief.

All assertions check the standard envelope: success bodies return the resource
directly; errors are ``{"error": {"code", "message", ...}}`` with the canonical
``code`` (validation_error / rate_limited / auth_invalid).
"""

from __future__ import annotations

from collections.abc import Iterator
from typing import Any
from unittest import mock

import pytest
from django.core.cache import cache
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient

from khatir.accounts.models import User
from khatir.core.enums import Channel
from khatir.core.models import SystemConfig

pytestmark = pytest.mark.django_db

PHONE = "+8801712345678"
SEND_OTP_PATH = "khatir.accounts.services.send_otp"


def _set_config(key: str, value: str) -> None:
    SystemConfig.objects.update_or_create(
        key=key, defaults={"value": value, "type": "int"}
    )


@pytest.fixture
def auth_config() -> Iterator[None]:
    """Seed the OTP tunables the T-001 migration would provide, then clear cache."""
    _set_config("otp_length", "6")
    _set_config("otp_ttl_seconds", "300")
    _set_config("otp_max_attempts", "5")
    _set_config("otp_resend_cooldown_seconds", "60")
    cache.clear()
    yield
    cache.clear()


@pytest.fixture
def client() -> APIClient:
    return APIClient()


@pytest.fixture
def mock_send() -> Iterator[mock.MagicMock]:
    """Patch the sender used inside the service so no real message is dispatched."""
    with mock.patch(SEND_OTP_PATH, return_value=Channel.INAPP) as m:
        yield m


# ── request-otp ───────────────────────────────────────────────────────────


def test_request_otp_success(
    client: APIClient, auth_config: None, mock_send: mock.MagicMock
) -> None:
    resp = client.post(reverse("accounts:request-otp"), {"phone": PHONE}, format="json")

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data == {"sent": True, "channel": Channel.INAPP.value}
    mock_send.assert_called_once()
    assert mock_send.call_args.args[0] == PHONE  # phone passed through
    # A code was actually generated and stored for later verification.
    assert cache.get(f"otp:{PHONE}") is not None


def test_request_otp_invalid_phone(
    client: APIClient, auth_config: None, mock_send: mock.MagicMock
) -> None:
    resp = client.post(
        reverse("accounts:request-otp"), {"phone": "01712345678"}, format="json"
    )

    assert resp.status_code == status.HTTP_400_BAD_REQUEST
    assert resp.data["error"]["code"] == "validation_error"
    assert "phone" in resp.data["error"]["details"]
    mock_send.assert_not_called()


def test_request_otp_cooldown(
    client: APIClient, auth_config: None, mock_send: mock.MagicMock
) -> None:
    first = client.post(reverse("accounts:request-otp"), {"phone": PHONE}, format="json")
    assert first.status_code == status.HTTP_200_OK

    second = client.post(reverse("accounts:request-otp"), {"phone": PHONE}, format="json")

    assert second.status_code == status.HTTP_429_TOO_MANY_REQUESTS
    assert second.data["error"]["code"] == "rate_limited"
    mock_send.assert_called_once()  # only the first request dispatched


# ── verify-otp ──────────────────────────────────────────────────────────────


def _issue_code(client: APIClient) -> str:
    """Request an OTP (sender mocked) and return the plaintext code from the store."""
    with mock.patch(SEND_OTP_PATH, return_value=Channel.INAPP) as m:
        client.post(reverse("accounts:request-otp"), {"phone": PHONE}, format="json")
        # The service hands the generated code to send_otp(phone, code).
        return str(m.call_args.args[1])


def test_verify_success_creates_user(client: APIClient, auth_config: None) -> None:
    code = _issue_code(client)
    assert not User.objects.filter(phone=PHONE).exists()

    resp = client.post(
        reverse("accounts:verify-otp"), {"phone": PHONE, "code": code}, format="json"
    )

    assert resp.status_code == status.HTTP_200_OK
    user = User.objects.get(phone=PHONE)
    body: dict[str, Any] = resp.data["user"]
    assert body["phone"] == PHONE
    assert body["id"] == str(user.pk)
    assert body["role"] == "landlord"  # default; real role set in EPIC-02
    # T-006 wires JWT issuance into verify-otp.
    assert resp.data["access"]
    assert resp.data["refresh"]


def test_verify_existing_user_reused(client: APIClient, auth_config: None) -> None:
    existing = User.objects.create_user(phone=PHONE, name="Existing")
    code = _issue_code(client)

    resp = client.post(
        reverse("accounts:verify-otp"), {"phone": PHONE, "code": code}, format="json"
    )

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data["user"]["id"] == str(existing.pk)
    assert User.objects.filter(phone=PHONE).count() == 1


def test_verify_wrong_code(client: APIClient, auth_config: None) -> None:
    _issue_code(client)

    resp = client.post(
        reverse("accounts:verify-otp"), {"phone": PHONE, "code": "000000"}, format="json"
    )

    assert resp.status_code == status.HTTP_401_UNAUTHORIZED
    assert resp.data["error"]["code"] == "auth_invalid"
    assert not User.objects.filter(phone=PHONE).exists()


def test_verify_expired_code(client: APIClient, auth_config: None) -> None:
    # No code was ever issued → the store has nothing → treated as expired.
    resp = client.post(
        reverse("accounts:verify-otp"), {"phone": PHONE, "code": "123456"}, format="json"
    )

    assert resp.status_code == status.HTTP_401_UNAUTHORIZED
    assert resp.data["error"]["code"] == "auth_invalid"
    assert not User.objects.filter(phone=PHONE).exists()


def test_verify_invalid_phone(client: APIClient, auth_config: None) -> None:
    resp = client.post(
        reverse("accounts:verify-otp"),
        {"phone": "not-a-phone", "code": "123456"},
        format="json",
    )

    assert resp.status_code == status.HTTP_400_BAD_REQUEST
    assert resp.data["error"]["code"] == "validation_error"
