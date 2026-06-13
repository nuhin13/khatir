"""Channel-agnostic notification sending (EPIC-01.T-004).

A generic :class:`~khatir.messaging.senders.NotificationSender` interface with
console / WhatsApp / SMS implementations and a :func:`~khatir.messaging.factory.get_sender`
selector, so the rest of the codebase can deliver a templated message to a
recipient without knowing or caring which channel carries it.

This module is deliberately **not** OTP-specific: it is the seed of the broader
notifications system (EPIC-15 extends it rather than duplicating it — T-004
§15). The OTP-specific ``send_otp`` helper lives in ``khatir.accounts`` and is
built on top of this layer.
"""

from .factory import get_sender
from .senders import (
    ConsoleSender,
    NotificationSender,
    SmsSender,
    WhatsAppSender,
)

__all__ = [
    "ConsoleSender",
    "NotificationSender",
    "SmsSender",
    "WhatsAppSender",
    "get_sender",
]
