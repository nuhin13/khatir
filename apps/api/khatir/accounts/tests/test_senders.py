"""Tests for the notification senders + selector (T-004 §12).

Covers the interface contract, the console sender logging, factory selection by
explicit channel and by config, the dev short-circuit, the WhatsApp/SMS provider
calls (HTTP mocked — no network), the missing-credentials configuration error,
and the WhatsApp→SMS fallback path. Also exercises the OTP ``send_otp`` helper.

Senders make HTTP via ``khatir.messaging.senders._post_json``; tests patch that
(or ``urlopen``) so nothing leaves the process.
"""

from __future__ import annotations

import logging
from typing import Any
from unittest import mock

import pytest

from khatir.accounts.notifications import send_otp
from khatir.core.enums import Channel
from khatir.core.exceptions import UpstreamUnavailableError, ValidationError
from khatir.core.models import SystemConfig
from khatir.messaging import (
    ConsoleSender,
    NotificationSender,
    SmsSender,
    WhatsAppSender,
    get_sender,
)
from khatir.messaging.factory import send_with_fallback

pytestmark = pytest.mark.django_db

PHONE = "+8801712345678"
MESSAGE = "hello"

_POST = "khatir.messaging.senders._post_json"


def _set_config(key: str, value: str, type_: str = "text") -> None:
    SystemConfig.objects.update_or_create(
        key=key, defaults={"value": value, "type": type_}
    )


@pytest.fixture
def capture_messaging_logs() -> Any:
    """Let pytest's ``caplog`` see ``khatir.messaging`` records.

    The project logging config sets ``propagate = False`` on the ``khatir``
    logger (so app logs don't double-emit through the root handler). ``caplog``
    installs its handler on the root logger, so without re-enabling propagation
    for the duration of the test it would capture nothing.
    """
    # Propagation must be re-enabled up the whole chain: ``khatir.messaging`` →
    # ``khatir`` (configured with propagate=False) → root, where caplog listens.
    names = ("khatir.messaging", "khatir")
    loggers = [logging.getLogger(name) for name in names]
    previous = [lg.propagate for lg in loggers]
    for lg in loggers:
        lg.propagate = True
    try:
        yield
    finally:
        for lg, prev in zip(loggers, previous, strict=True):
            lg.propagate = prev


@pytest.fixture
def prod_env(settings: Any) -> None:
    """Switch out of the dev short-circuit so prod selection paths run."""
    settings.DJANGO_ENV = "prod"


@pytest.fixture
def whatsapp_creds(settings: Any) -> None:
    settings.WHATSAPP_API_URL = "https://wa.example.com"
    settings.WHATSAPP_API_TOKEN = "wa-token"
    settings.WHATSAPP_PHONE_ID = "phone-123"


@pytest.fixture
def sms_creds(settings: Any) -> None:
    settings.SMS_GATEWAY_URL = "https://sms.example.com/send"
    settings.SMS_GATEWAY_KEY = "sms-key"


# ── Interface contract ────────────────────────────────────────────────


def test_all_senders_are_notification_senders() -> None:
    for cls in (ConsoleSender, SmsSender, WhatsAppSender):
        assert issubclass(cls, NotificationSender)
        assert cls().channel in Channel


def test_interface_cannot_be_instantiated() -> None:
    with pytest.raises(TypeError):
        NotificationSender()  # type: ignore[abstract]


# ── Console sender ────────────────────────────────────────────────────


def test_console_sender_logs(
    capture_messaging_logs: None, caplog: pytest.LogCaptureFixture
) -> None:
    with caplog.at_level(logging.INFO, logger="khatir.messaging"):
        ConsoleSender().send(PHONE, MESSAGE, channel=Channel.INAPP)
    # The recipient + message are logged (the phone is PII-masked by the global
    # filter to its last four digits — code/OTP would be masked too).
    assert "5678" in caplog.text
    assert MESSAGE in caplog.text


# ── Factory selection ─────────────────────────────────────────────────


def test_get_sender_by_explicit_channel() -> None:
    assert isinstance(get_sender(Channel.WHATSAPP), WhatsAppSender)
    assert isinstance(get_sender(Channel.SMS), SmsSender)
    assert isinstance(get_sender(Channel.INAPP), ConsoleSender)


def test_get_sender_dev_defaults_to_console(settings: Any) -> None:
    settings.DJANGO_ENV = "dev"
    assert isinstance(get_sender(), ConsoleSender)


def test_get_sender_uses_primary_channel_config(prod_env: None) -> None:
    _set_config("auth_primary_channel", "sms")
    assert isinstance(get_sender(), SmsSender)
    _set_config("auth_primary_channel", "whatsapp")
    assert isinstance(get_sender(), WhatsAppSender)


def test_get_sender_invalid_config_channel(prod_env: None) -> None:
    _set_config("auth_primary_channel", "carrier-pigeon")
    with pytest.raises(ValidationError):
        get_sender()


# ── WhatsApp / SMS provider calls (HTTP mocked) ───────────────────────


def test_whatsapp_sender_posts_expected_payload(whatsapp_creds: None) -> None:
    with mock.patch(_POST) as post:
        WhatsAppSender().send(PHONE, MESSAGE, channel=Channel.WHATSAPP)
    post.assert_called_once()
    args, kwargs = post.call_args
    assert args[0] == "https://wa.example.com/phone-123/messages"
    assert kwargs["token"] == "wa-token"
    assert kwargs["payload"]["to"] == PHONE
    assert kwargs["payload"]["text"]["body"] == MESSAGE


def test_sms_sender_posts_expected_payload(sms_creds: None) -> None:
    with mock.patch(_POST) as post:
        SmsSender().send(PHONE, MESSAGE, channel=Channel.SMS)
    post.assert_called_once()
    args, kwargs = post.call_args
    assert args[0] == "https://sms.example.com/send"
    assert kwargs["token"] == "sms-key"
    assert kwargs["payload"] == {"to": PHONE, "message": MESSAGE}


def test_whatsapp_missing_creds_raises(settings: Any) -> None:
    settings.WHATSAPP_API_URL = ""
    settings.WHATSAPP_API_TOKEN = ""
    settings.WHATSAPP_PHONE_ID = ""
    with pytest.raises(UpstreamUnavailableError):
        WhatsAppSender().send(PHONE, MESSAGE, channel=Channel.WHATSAPP)


def test_sms_missing_creds_raises(settings: Any) -> None:
    settings.SMS_GATEWAY_URL = ""
    settings.SMS_GATEWAY_KEY = ""
    with pytest.raises(UpstreamUnavailableError):
        SmsSender().send(PHONE, MESSAGE, channel=Channel.SMS)


# ── Fallback path ─────────────────────────────────────────────────────


def test_fallback_whatsapp_to_sms(
    prod_env: None, whatsapp_creds: None, sms_creds: None
) -> None:
    _set_config("auth_primary_channel", "whatsapp")

    def fail_for_whatsapp(url: str, *, token: str, payload: dict[str, Any]) -> None:
        if token == "wa-token":
            raise UpstreamUnavailableError("WhatsApp down")
        # SMS call succeeds (no-op)

    with mock.patch(_POST, side_effect=fail_for_whatsapp) as post:
        delivered = send_with_fallback(PHONE, MESSAGE)

    assert delivered == Channel.SMS
    assert post.call_count == 2  # WhatsApp tried, then SMS


def test_fallback_all_fail_reraises(
    prod_env: None, whatsapp_creds: None, sms_creds: None
) -> None:
    _set_config("auth_primary_channel", "whatsapp")
    with mock.patch(_POST, side_effect=UpstreamUnavailableError("down")):
        with pytest.raises(UpstreamUnavailableError):
            send_with_fallback(PHONE, MESSAGE)


def test_send_with_fallback_dev_uses_console(
    settings: Any,
    capture_messaging_logs: None,
    caplog: pytest.LogCaptureFixture,
) -> None:
    settings.DJANGO_ENV = "dev"
    with caplog.at_level(logging.INFO, logger="khatir.messaging"):
        delivered = send_with_fallback(PHONE, MESSAGE)
    assert delivered == Channel.INAPP
    assert "5678" in caplog.text


# ── send_otp helper ───────────────────────────────────────────────────


def test_send_otp_dev_logs_bilingual_message(
    settings: Any,
    capture_messaging_logs: None,
    caplog: pytest.LogCaptureFixture,
) -> None:
    settings.DJANGO_ENV = "dev"
    _set_config("otp_ttl_seconds", "300", "int")
    with caplog.at_level(logging.INFO, logger="khatir.messaging"):
        delivered = send_otp(PHONE, "123456")
    assert delivered == Channel.INAPP
    # Both language lines present; validity rounded to 5 minutes.
    assert "Khatir verification code" in caplog.text
    assert "খাতির" in caplog.text
    assert "5 minutes" in caplog.text
