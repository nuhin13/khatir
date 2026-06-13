"""Signed open-tracking tokens for notification deliveries — EPIC-15 T-004.

A :class:`~khatir.notifications.models.NotificationDelivery` carries no login of
its own, yet the web "opened" beacon (a 1×1 tracking pixel embedded in a web
link / receipt page, see T-004 §1) must be unforgeable: a recipient must not be
able to mark *another* delivery opened by guessing an integer id. So the beacon
URL embeds a **signed, tamper-evident token** that encodes only the delivery's
pk, signed with Django's :class:`~django.core.signing.Signer` under a dedicated
salt (namespaced away from the rent link-token salt and every other signed
payload in the project).

Open tokens deliberately **do not expire**: a recipient may open a broadcast
days later and that open is still meaningful telemetry, so — unlike the rent
link token (:mod:`khatir.rent.tokens`) — a plain :class:`Signer` is used rather
than a :class:`TimestampSigner`.

:func:`resolve_token` verifies the signature and returns the live delivery, or
raises :class:`InvalidTrackingToken` (a
:class:`~khatir.core.exceptions.NotFoundError`) for a malformed / tampered /
unknown token so the beacon view resolves it to an opaque pixel response without
ever revealing *why* it failed.
"""

from __future__ import annotations

from django.core import signing
from django.urls import reverse

from khatir.core.exceptions import NotFoundError

from .models import NotificationDelivery

# Dedicated salt so open tokens are namespaced away from every other signed
# payload in the project (rent link tokens, sessions, password resets, …).
_TOKEN_SALT = "khatir.notifications.open_token"


class InvalidTrackingToken(NotFoundError):
    """The token is malformed, tampered with, or its delivery no longer exists."""


def _signer() -> signing.Signer:
    return signing.Signer(salt=_TOKEN_SALT)


def make_token(delivery: NotificationDelivery) -> str:
    """Mint a signed open-tracking token for ``delivery`` (signs its pk)."""
    return _signer().sign(str(delivery.pk))


def beacon_path(delivery: NotificationDelivery) -> str:
    """Return the root-relative open-beacon URL for ``delivery``.

    Embed this in a web link / receipt page (EPIC-07) as a 1×1 ``<img>`` src;
    the first fetch records the open. Returns a path (not an absolute URL) so the
    caller composes the host that fits the surface (admin vs. tenant origin).
    """
    return reverse(
        "notifications_web:open-beacon", kwargs={"token": make_token(delivery)}
    )


def resolve_token(token: str) -> NotificationDelivery:
    """Return the live :class:`NotificationDelivery` a valid ``token`` points at.

    Raises :class:`InvalidTrackingToken` when the token is malformed, tampered,
    or its delivery no longer exists.
    """
    try:
        raw = _signer().unsign(token)
    except signing.BadSignature as exc:
        raise InvalidTrackingToken("This tracking link is invalid.") from exc

    try:
        return NotificationDelivery.objects.get(pk=int(raw))
    except (NotificationDelivery.DoesNotExist, ValueError) as exc:
        raise InvalidTrackingToken("This tracking link is invalid.") from exc
