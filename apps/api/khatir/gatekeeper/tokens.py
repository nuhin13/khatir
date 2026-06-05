"""Signed visitor web-link token service (EPIC-25 T-004).

Reuses the EPIC-07 T-002 signing pattern, but scoped to a **building** rather
than a single rent request or a unit: it lets a visitor (or the caretaker on a
shared gate device) open the visitor sign-in web page for one building without
an app or login. The token encodes only the building id; it is signed with
Django's :class:`TimestampSigner` under a dedicated salt (so a visitor token can
never be mistaken for a rent link-token, a maintenance token, or any other
signed payload) and validated against a TTL read from
``visitor_link_token_ttl_hours`` (Layer-3 config).

The signature makes the token unguessable and tamper-evident, and the timestamp
makes it expire. Like the maintenance token, a visitor token is **not** tied to
a one-shot record, so there is nothing per-token to persist — it is purely a
stateless capability for a building (hence no DB change). ``make_token`` mints a
token for a ``Building``; ``resolve_token`` verifies the signature, enforces the
TTL, and returns the live ``Building``.

On failure it raises a subclass of :class:`~khatir.core.exceptions.NotFoundError`
— :class:`ExpiredVisitorToken` when the signature is valid but past its TTL, and
:class:`InvalidVisitorToken` for a malformed/tampered/unknown token. Both
subclass ``NotFoundError`` so a JSON API caller still resolves them to an opaque
404 (a visitor must never learn *why* a link failed), while the server-rendered
web page (T-005) can distinguish "expired" (410) from "invalid" (404).
"""

from __future__ import annotations

from django.core import signing

from khatir.core.config import get_config
from khatir.core.exceptions import NotFoundError
from khatir.properties.models import Building

# Dedicated salt so these tokens are namespaced away from every other signed
# payload in the project (rent/maintenance link-tokens, sessions, etc.).
_TOKEN_SALT = "khatir.gatekeeper.visitor_link_token"

# Fallback TTL (hours) when ``visitor_link_token_ttl_hours`` is not seeded yet
# (it is seeded by T-012). A building's gate sign-in link is a longer-lived,
# reusable capability (it is posted at the gate, not mailed once), so it
# defaults to 30 days rather than the rent/maintenance 72h.
_DEFAULT_TTL_HOURS = 24 * 30


class InvalidVisitorToken(NotFoundError):
    """The token is malformed, tampered with, or its building no longer exists."""


class ExpiredVisitorToken(NotFoundError):
    """The token's signature is valid but it is past its TTL."""


def _signer() -> signing.TimestampSigner:
    return signing.TimestampSigner(salt=_TOKEN_SALT)


def _ttl_seconds() -> int:
    hours = int(get_config("visitor_link_token_ttl_hours", default=_DEFAULT_TTL_HOURS))
    return hours * 3600


def make_token(building: Building) -> str:
    """Mint a signed, expiring visitor token for ``building`` and return it.

    The token signs the building's pk, so one token grants access to exactly one
    building's visitor sign-in page. It is stateless (nothing is persisted): a
    building may be issued any number of valid tokens.
    """
    return _signer().sign(str(building.pk))


def resolve_token(token: str) -> Building:
    """Return the live ``Building`` a valid, unexpired ``token`` points at.

    Raises :class:`ExpiredVisitorToken` when the signature is valid but past its
    TTL, and :class:`InvalidVisitorToken` when the token is malformed, tampered,
    or its building no longer exists. Both subclass
    :class:`~khatir.core.exceptions.NotFoundError`.
    """
    try:
        raw = _signer().unsign(token, max_age=_ttl_seconds())
    except signing.SignatureExpired as exc:
        raise ExpiredVisitorToken("This visitor link has expired.") from exc
    except signing.BadSignature as exc:
        raise InvalidVisitorToken("This visitor link is invalid.") from exc

    try:
        return Building.objects.get(pk=int(raw))
    except (Building.DoesNotExist, ValueError) as exc:
        raise InvalidVisitorToken("This visitor link is invalid.") from exc
