"""Signed link-token service for rent requests (EPIC-07 T-002).

Generates and validates **signed, single-purpose, expiring** tokens that grant
access to exactly one ``RentRequest``'s web page — no login, no app. The token
encodes only the request id; it is signed with Django's :class:`TimestampSigner`
under a dedicated salt (so a token minted here can never be mistaken for one of
Django's other signed payloads) and validated against a TTL read from
``rent_link_token_ttl_hours`` (Layer-3 config).

The signature makes the token unguessable and tamper-evident, and the timestamp
makes it expire. ``make_token`` also persists the issued token on the request
(``link_token``) so the web page can be resolved by token lookup; ``resolve_token``
verifies the signature, enforces the TTL, and returns the live ``RentRequest``.

On failure it raises a subclass of :class:`~khatir.core.exceptions.NotFoundError`
— :class:`ExpiredLinkToken` when the signature is valid but past its TTL, and
:class:`InvalidLinkToken` for a malformed/tampered/unknown token. Both subclass
``NotFoundError`` so a JSON API caller still resolves them to an opaque 404 (a
tenant must never learn *why* a link failed), while the server-rendered web page
(T-005) can distinguish "expired" (410) from "invalid" (404).
"""

from __future__ import annotations

from django.core import signing

from khatir.core.config import get_config
from khatir.core.exceptions import NotFoundError

from .models import RentRequest

# Dedicated salt so these tokens are namespaced away from every other signed
# payload in the project (sessions, password resets, etc.).
_TOKEN_SALT = "khatir.rent.link_token"

# Fallback TTL (hours) when ``rent_link_token_ttl_hours`` is not seeded yet
# (it is seeded by T-009). 72h = three days for a tenant to act on a link.
_DEFAULT_TTL_HOURS = 72


class InvalidLinkToken(NotFoundError):
    """The token is malformed, tampered with, or its request no longer exists."""


class ExpiredLinkToken(NotFoundError):
    """The token's signature is valid but it is past its TTL."""


def _signer() -> signing.TimestampSigner:
    return signing.TimestampSigner(salt=_TOKEN_SALT)


def _ttl_seconds() -> int:
    hours = int(get_config("rent_link_token_ttl_hours", default=_DEFAULT_TTL_HOURS))
    return hours * 3600


def make_token(rent_request: RentRequest, *, persist: bool = True) -> str:
    """Mint a signed, expiring token for ``rent_request`` and return it.

    One token maps to exactly one request (it signs the request's pk). By default
    the token is also persisted on ``rent_request.link_token`` so it can later be
    resolved by a plain DB lookup; pass ``persist=False`` to mint without saving.
    """
    token = _signer().sign(str(rent_request.pk))
    if persist:
        rent_request.link_token = token
        rent_request.save(update_fields=["link_token", "updated_at"])
    return token


def resolve_token(token: str) -> RentRequest:
    """Return the live ``RentRequest`` a valid, unexpired ``token`` points at.

    Raises :class:`ExpiredLinkToken` when the signature is valid but past its
    TTL, and :class:`InvalidLinkToken` when the token is malformed, tampered, or
    its request no longer exists. Both subclass
    :class:`~khatir.core.exceptions.NotFoundError`.
    """
    try:
        raw = _signer().unsign(token, max_age=_ttl_seconds())
    except signing.SignatureExpired as exc:
        raise ExpiredLinkToken("This rent link has expired.") from exc
    except signing.BadSignature as exc:
        raise InvalidLinkToken("This rent link is invalid.") from exc

    try:
        return RentRequest.objects.get(pk=int(raw))
    except (RentRequest.DoesNotExist, ValueError) as exc:
        raise InvalidLinkToken("This rent link is invalid.") from exc
