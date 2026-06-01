"""Rate-limit tests for the OTP auth endpoints (T-007 §12).

Drives ``request-otp`` and ``verify-otp`` through DRF's ``APIClient`` and asserts
that exceeding the per-phone / per-IP throttle window returns ``429`` with the
standard ``rate_limited`` envelope, while staying under the window passes.

Throttle state lives in the cache (LocMem in ``settings.test``); the autouse
``_clear_cache`` fixture (root ``conftest``) resets it between tests. The OTP
resend cooldown (T-003) is set to ``0`` here so it does not pre-empt the broader
throttle being exercised — the two layers are independent (T-007 §15).
"""

from __future__ import annotations

from collections.abc import Iterator
from unittest import mock

import pytest
from django.conf import settings
from django.core.cache import cache
from django.test import override_settings
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient

from khatir.core.enums import Channel
from khatir.core.models import SystemConfig

pytestmark = pytest.mark.django_db


def _rest_framework_with_rates(rates: dict[str, str]) -> dict[str, object]:
    """Return the project REST_FRAMEWORK config with throttle rates swapped in.

    Replacing the whole dict via ``override_settings`` would drop the custom
    ``EXCEPTION_HANDLER`` (and so the ``rate_limited`` envelope), so merge.
    """
    return {**settings.REST_FRAMEWORK, "DEFAULT_THROTTLE_RATES": rates}


PHONE = "+8801712345678"
OTHER_PHONE = "+8801799999999"
SEND_OTP_PATH = "khatir.accounts.services.send_otp"

# Tight rates so the windows are cheap to exhaust in a test.
TEST_RATES = {
    "request_otp_phone": "2/hour",
    "request_otp_ip": "100/hour",
    "verify_otp_phone": "2/min",
    "verify_otp_ip": "100/min",
}
TEST_RATES_IP = {
    "request_otp_phone": "100/hour",
    "request_otp_ip": "2/hour",
    "verify_otp_phone": "100/min",
    "verify_otp_ip": "100/min",
}


def _set_config(key: str, value: str) -> None:
    SystemConfig.objects.update_or_create(
        key=key, defaults={"value": value, "type": "int"}
    )


@pytest.fixture
def auth_config() -> Iterator[None]:
    """Seed OTP tunables; disable the resend cooldown so it doesn't interfere."""
    _set_config("otp_length", "6")
    _set_config("otp_ttl_seconds", "300")
    _set_config("otp_max_attempts", "5")
    _set_config("otp_resend_cooldown_seconds", "0")
    cache.clear()
    yield
    cache.clear()


@pytest.fixture
def client() -> APIClient:
    return APIClient()


@pytest.fixture
def mock_send() -> Iterator[mock.MagicMock]:
    with mock.patch(SEND_OTP_PATH, return_value=Channel.INAPP) as m:
        yield m


def _request_otp(client: APIClient, phone: str = PHONE):  # type: ignore[no-untyped-def]
    return client.post(
        reverse("accounts:request-otp"), {"phone": phone}, format="json"
    )


def _verify_otp(client: APIClient, phone: str = PHONE, code: str = "000000"):  # type: ignore[no-untyped-def]
    return client.post(
        reverse("accounts:verify-otp"), {"phone": phone, "code": code}, format="json"
    )


def _assert_rate_limited(resp) -> None:  # type: ignore[no-untyped-def]
    assert resp.status_code == status.HTTP_429_TOO_MANY_REQUESTS
    assert resp.data["error"]["code"] == "rate_limited"
    assert "message" in resp.data["error"]


# ── request-otp ────────────────────────────────────────────────────────────


@override_settings(REST_FRAMEWORK=_rest_framework_with_rates(TEST_RATES))
def test_request_otp_under_limit_passes(
    client: APIClient, auth_config: None, mock_send: mock.MagicMock
) -> None:
    for _ in range(2):  # limit is 2/hour/phone
        resp = _request_otp(client)
        assert resp.status_code == status.HTTP_200_OK


@override_settings(REST_FRAMEWORK=_rest_framework_with_rates(TEST_RATES))
def test_request_otp_per_phone_limit_returns_429(
    client: APIClient, auth_config: None, mock_send: mock.MagicMock
) -> None:
    assert _request_otp(client).status_code == status.HTTP_200_OK
    assert _request_otp(client).status_code == status.HTTP_200_OK

    _assert_rate_limited(_request_otp(client))  # 3rd call → over the phone limit
    assert mock_send.call_count == 2  # the throttled call never dispatched


@override_settings(REST_FRAMEWORK=_rest_framework_with_rates(TEST_RATES))
def test_request_otp_other_phone_not_blocked(
    client: APIClient, auth_config: None, mock_send: mock.MagicMock
) -> None:
    # Exhaust the per-phone window for PHONE.
    _request_otp(client)
    _request_otp(client)
    _assert_rate_limited(_request_otp(client))

    # A different phone has its own bucket and still succeeds (IP limit is high).
    assert _request_otp(client, OTHER_PHONE).status_code == status.HTTP_200_OK


@override_settings(REST_FRAMEWORK=_rest_framework_with_rates(TEST_RATES_IP))
def test_request_otp_per_ip_limit_returns_429(
    client: APIClient, auth_config: None, mock_send: mock.MagicMock
) -> None:
    # IP limit is 2/hour regardless of phone; different phones share the IP bucket.
    assert _request_otp(client, PHONE).status_code == status.HTTP_200_OK
    assert _request_otp(client, OTHER_PHONE).status_code == status.HTTP_200_OK

    _assert_rate_limited(_request_otp(client, "+8801700000000"))


# ── verify-otp ──────────────────────────────────────────────────────────────


@override_settings(REST_FRAMEWORK=_rest_framework_with_rates(TEST_RATES))
def test_verify_under_limit_passes(client: APIClient, auth_config: None) -> None:
    # Wrong codes (401), but under the throttle window — never 429.
    for _ in range(2):  # limit is 2/min/phone
        resp = _verify_otp(client)
        assert resp.status_code == status.HTTP_401_UNAUTHORIZED


@override_settings(REST_FRAMEWORK=_rest_framework_with_rates(TEST_RATES))
def test_verify_per_phone_limit_returns_429(
    client: APIClient, auth_config: None
) -> None:
    assert _verify_otp(client).status_code == status.HTTP_401_UNAUTHORIZED
    assert _verify_otp(client).status_code == status.HTTP_401_UNAUTHORIZED

    _assert_rate_limited(_verify_otp(client))  # 3rd attempt → over the phone limit
