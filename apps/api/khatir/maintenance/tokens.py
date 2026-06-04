"""Signed maintenance web-link token service (EPIC-08 T-004).

Reuses the EPIC-07 T-002 signing pattern, but scoped to a **unit** rather than a
single rent request: it lets a tenant open the maintenance web form for their
unit without an app or login. The token encodes only the unit id; it is signed
with Django's :class:`TimestampSigner` under a dedicated salt (so a maintenance
token can never be mistaken for a rent link-token or any other signed payload)
and validated against a TTL read from ``maintenance_link_token_ttl_hours``
(Layer-3 config).

The signature makes the token unguessable and tamper-evident, and the timestamp
makes it expire. Unlike the rent link-token, a maintenance token is **not** tied
to a one-shot request, so there is nothing per-token to persist — it is purely a
stateless capability for a unit (hence no DB change). ``make_token`` mints a
token for a ``Unit``; ``resolve_token`` verifies the signature, enforces the TTL,
and returns the live ``Unit``.

On failure it raises a subclass of :class:`~khatir.core.exceptions.NotFoundError`
— :class:`ExpiredMaintenanceToken` when the signature is valid but past its TTL,
and :class:`InvalidMaintenanceToken` for a malformed/tampered/unknown token. Both
subclass ``NotFoundError`` so a JSON API caller still resolves them to an opaque
404 (a tenant must never learn *why* a link failed), while the server-rendered
web form (T-005) can distinguish "expired" (410) from "invalid" (404).
"""

from __future__ import annotations

from django.core import signing

from khatir.core.config import get_config
from khatir.core.exceptions import NotFoundError
from khatir.properties.models import Unit

# Dedicated salt so these tokens are namespaced away from every other signed
# payload in the project (rent link-tokens, sessions, password resets, etc.).
_TOKEN_SALT = "khatir.maintenance.link_token"

# Fallback TTL (hours) when ``maintenance_link_token_ttl_hours`` is not seeded
# yet. 72h = three days for a tenant to act on a link, matching the rent
# link-token default.
_DEFAULT_TTL_HOURS = 72


class InvalidMaintenanceToken(NotFoundError):
    """The token is malformed, tampered with, or its unit no longer exists."""


class ExpiredMaintenanceToken(NotFoundError):
    """The token's signature is valid but it is past its TTL."""


def _signer() -> signing.TimestampSigner:
    return signing.TimestampSigner(salt=_TOKEN_SALT)


def _ttl_seconds() -> int:
    hours = int(get_config("maintenance_link_token_ttl_hours", default=_DEFAULT_TTL_HOURS))
    return hours * 3600


def make_token(unit: Unit) -> str:
    """Mint a signed, expiring maintenance token for ``unit`` and return it.

    The token signs the unit's pk, so one token grants access to exactly one
    unit's maintenance web form. It is stateless (nothing is persisted): a unit
    may be issued any number of valid tokens.
    """
    return _signer().sign(str(unit.pk))


def resolve_token(token: str) -> Unit:
    """Return the live ``Unit`` a valid, unexpired ``token`` points at.

    Raises :class:`ExpiredMaintenanceToken` when the signature is valid but past
    its TTL, and :class:`InvalidMaintenanceToken` when the token is malformed,
    tampered, or its unit no longer exists. Both subclass
    :class:`~khatir.core.exceptions.NotFoundError`.
    """
    try:
        raw = _signer().unsign(token, max_age=_ttl_seconds())
    except signing.SignatureExpired as exc:
        raise ExpiredMaintenanceToken("This maintenance link has expired.") from exc
    except signing.BadSignature as exc:
        raise InvalidMaintenanceToken("This maintenance link is invalid.") from exc

    try:
        return Unit.objects.get(pk=int(raw))
    except (Unit.DoesNotExist, ValueError) as exc:
        raise InvalidMaintenanceToken("This maintenance link is invalid.") from exc
