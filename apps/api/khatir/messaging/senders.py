"""The ``NotificationSender`` interface and its concrete implementations.

Three senders implement one generic contract — ``send(recipient, message, *,
channel)`` — so callers stay channel-agnostic (T-004 §3):

* :class:`ConsoleSender` — dev/default. Logs the message; never calls out, so
  the app is fully buildable and testable with no WhatsApp/SMS account.
* :class:`WhatsAppSender` — posts to the WhatsApp Business API. Credentials come
  from ``WHATSAPP_*`` env; if unset it raises a clear configuration error rather
  than failing silently.
* :class:`SmsSender` — posts to the SMS gateway. Credentials come from
  ``SMS_*`` env, same fail-loud contract.

The interface is intentionally generic (not OTP-specific) so EPIC-15 can build
the full notifications system on top of it. Message bodies are **never** logged
verbatim by the real senders (they may carry OTP codes — see
``04_coding_conventions.md`` §10); the console sender relies on the global
PII-masking log filter to redact codes.
"""

from __future__ import annotations

import json
import logging
from abc import ABC, abstractmethod
from typing import Any, Final
from urllib import error as urllib_error
from urllib import request as urllib_request

from django.conf import settings

from khatir.core.enums import Channel
from khatir.core.exceptions import UpstreamUnavailableError

logger = logging.getLogger("khatir.messaging")

_HTTP_TIMEOUT: Final = 10  # seconds — external messaging calls must not hang.


class NotificationSender(ABC):
    """Generic contract for delivering a message to a recipient over a channel.

    Implementations are channel-specific but the signature is uniform so callers
    (OTP today, the full notifications system in EPIC-15) never branch on
    channel themselves — they ask the factory for a sender and call
    :meth:`send`.
    """

    #: The channel this sender delivers over (set by each concrete subclass).
    channel: Channel

    @abstractmethod
    def send(self, recipient: str, message: str, *, channel: Channel) -> None:
        """Deliver ``message`` to ``recipient``.

        ``channel`` is accepted for interface symmetry and validation; a
        concrete sender delivers over its own :attr:`channel` and may reject a
        mismatching request. Implementations raise
        :class:`~khatir.core.exceptions.UpstreamUnavailableError` on delivery
        failure and a configuration error when required credentials are unset.
        """
        raise NotImplementedError


def _post_json(url: str, *, token: str, payload: dict[str, Any]) -> None:
    """POST ``payload`` as JSON with a bearer token; raise on transport failure.

    Uses the stdlib HTTP client so the messaging layer adds no dependency and
    the app stays buildable; tests patch this function (or ``urlopen``) rather
    than hitting the network. Never logs the payload (it may carry a code).
    """
    data = json.dumps(payload).encode("utf-8")
    req = urllib_request.Request(  # noqa: S310 — url is operator-configured, not user input
        url,
        data=data,
        method="POST",
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib_request.urlopen(req, timeout=_HTTP_TIMEOUT) as resp:  # noqa: S310
            status = resp.status
    except urllib_error.URLError as exc:
        raise UpstreamUnavailableError(
            "Messaging provider could not be reached."
        ) from exc

    if not 200 <= status < 300:
        raise UpstreamUnavailableError(
            f"Messaging provider returned HTTP {status}."
        )


class ConsoleSender(NotificationSender):
    """Development sender that logs the message instead of calling out.

    This is the safe default: no external account is needed, so OTP (and any
    other notification) can be exercised end-to-end in dev and tests. The
    rendered message is logged at INFO; the global PII-masking filter
    (``core/logging.py``) redacts any embedded code/token before it is emitted.
    """

    channel = Channel.INAPP

    def send(self, recipient: str, message: str, *, channel: Channel) -> None:
        logger.info(
            "console notification to %s via %s: %s",
            recipient,
            channel.value if isinstance(channel, Channel) else channel,
            message,
        )


class WhatsAppSender(NotificationSender):
    """Sends via the WhatsApp Business API; credentials from ``WHATSAPP_*`` env.

    Raises :class:`~khatir.core.exceptions.UpstreamUnavailableError` if the
    credentials are unset (caught upstream) rather than failing silently, and on
    any transport/HTTP error so the selector can fall back to SMS.
    """

    channel = Channel.WHATSAPP

    def send(self, recipient: str, message: str, *, channel: Channel) -> None:
        url = settings.WHATSAPP_API_URL
        token = settings.WHATSAPP_API_TOKEN
        phone_id = settings.WHATSAPP_PHONE_ID
        if not (url and token and phone_id):
            raise UpstreamUnavailableError(
                "WhatsApp is not configured (WHATSAPP_API_URL / "
                "WHATSAPP_API_TOKEN / WHATSAPP_PHONE_ID unset)."
            )
        _post_json(
            f"{url.rstrip('/')}/{phone_id}/messages",
            token=token,
            payload={
                "messaging_product": "whatsapp",
                "to": recipient,
                "type": "text",
                "text": {"body": message},
            },
        )


class SmsSender(NotificationSender):
    """Sends via the SMS gateway; credentials from ``SMS_*`` env.

    Same fail-loud contract as :class:`WhatsAppSender`: a clear configuration
    error when credentials are unset, and an upstream error on transport/HTTP
    failure.
    """

    channel = Channel.SMS

    def send(self, recipient: str, message: str, *, channel: Channel) -> None:
        url = settings.SMS_GATEWAY_URL
        key = settings.SMS_GATEWAY_KEY
        if not (url and key):
            raise UpstreamUnavailableError(
                "SMS is not configured (SMS_GATEWAY_URL / SMS_GATEWAY_KEY unset)."
            )
        _post_json(
            url,
            token=key,
            payload={"to": recipient, "message": message},
        )
