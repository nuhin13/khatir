"""Sender selection: pick a :class:`NotificationSender` by channel or config.

Selection rules (T-004 §3, §13):

* **Dev** (``DJANGO_ENV=dev``) always uses :class:`ConsoleSender` — no external
  account is needed, so the whole app is buildable/testable without WhatsApp or
  SMS approval. Console is the safe default.
* **Otherwise** the primary channel is read from the ``auth_primary_channel``
  ``SystemConfig`` (default ``whatsapp``); WhatsApp falls back to SMS so a
  WhatsApp outage still delivers (``send_with_fallback``).
* Callers that already know the channel can ask for it directly via
  ``get_sender(channel=...)``.

The registry maps each :class:`~khatir.core.enums.Channel` to its sender so
later epics register additional channels (e.g. EMAIL) in one place.
"""

from __future__ import annotations

import logging
from collections.abc import Callable

from django.conf import settings

from khatir.core.config import get_config
from khatir.core.enums import Channel
from khatir.core.exceptions import UpstreamUnavailableError, ValidationError

from .senders import (
    ConsoleSender,
    NotificationSender,
    SmsSender,
    WhatsAppSender,
)

logger = logging.getLogger("khatir.messaging")

#: Channel → sender constructor. Console handles INAPP (and is the dev default).
_REGISTRY: dict[Channel, Callable[[], NotificationSender]] = {
    Channel.INAPP: ConsoleSender,
    Channel.WHATSAPP: WhatsAppSender,
    Channel.SMS: SmsSender,
}

#: Order tried when delivering over the configured primary channel in prod.
_FALLBACK_ORDER: dict[Channel, list[Channel]] = {
    Channel.WHATSAPP: [Channel.WHATSAPP, Channel.SMS],
    Channel.SMS: [Channel.SMS],
}


def _is_dev() -> bool:
    return bool(settings.DJANGO_ENV == "dev")


def get_sender(channel: Channel | None = None) -> NotificationSender:
    """Return the sender to use.

    * ``channel`` given → the sender registered for that channel (explicit
      override; ignores the dev short-circuit so prod paths can be tested).
    * ``channel`` omitted → :class:`ConsoleSender` in dev, otherwise the sender
      for the configured ``auth_primary_channel``.

    Raises :class:`~khatir.core.exceptions.ValidationError` for an unknown
    channel value.
    """
    if channel is None:
        if _is_dev():
            return ConsoleSender()
        channel = _resolve_primary_channel()

    try:
        return _REGISTRY[channel]()
    except KeyError as exc:
        raise ValidationError(f"No notification sender for channel '{channel}'.") from exc


def _resolve_primary_channel() -> Channel:
    """Read ``auth_primary_channel`` config and coerce it to a :class:`Channel`."""
    raw = get_config("auth_primary_channel", default=Channel.WHATSAPP.value)
    try:
        return Channel(raw)
    except ValueError as exc:
        raise ValidationError(
            f"Configured auth_primary_channel '{raw}' is not a valid channel."
        ) from exc


def send_with_fallback(recipient: str, message: str) -> Channel:
    """Deliver ``message`` to ``recipient`` over the configured channel + fallback.

    In dev, sends via console and returns :attr:`Channel.INAPP`. Otherwise tries
    the configured primary channel, falling back through :data:`_FALLBACK_ORDER`
    (WhatsApp → SMS) on an :class:`UpstreamUnavailableError`. Returns the channel
    that actually delivered; re-raises the last error if every channel fails.
    """
    if _is_dev():
        ConsoleSender().send(recipient, message, channel=Channel.INAPP)
        return Channel.INAPP

    primary = _resolve_primary_channel()
    order = _FALLBACK_ORDER.get(primary, [primary])
    last_error: UpstreamUnavailableError | None = None
    for channel in order:
        sender = get_sender(channel)
        try:
            sender.send(recipient, message, channel=channel)
        except UpstreamUnavailableError as exc:
            logger.warning(
                "notification delivery over %s failed; trying next channel",
                channel.value,
            )
            last_error = exc
            continue
        return channel

    assert last_error is not None  # noqa: S101 — order is never empty
    raise last_error
