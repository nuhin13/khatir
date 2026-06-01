"""Accounts service layer (business logic; no logic in views — T-003/T-005 §2).

Re-exports the OTP lifecycle primitives (T-003) so callers import account
services from one place, and adds the two auth use-cases consumed by the
endpoints in T-005:

* :func:`request_otp` — cooldown check → generate (T-003) → dispatch (T-004).
* :func:`verify_otp_and_get_user` — verify (T-003) → get-or-create the ``User``.

Views stay thin: they validate input, call one of these, serialize the result.
Failures are raised as typed exceptions from ``core.exceptions`` so the handler
maps them to the standard error envelope. JWT issuance is **not** done here — it
is T-006; verify returns the ``User`` for T-006 to mint tokens from.
"""

from __future__ import annotations

import logging

from django.conf import settings
from django.utils import timezone

from khatir.core.enums import Channel
from khatir.core.exceptions import AuthInvalidError, RateLimitedError

from .auth_tokens import issue_tokens
from .models import User
from .notifications import send_otp
from .otp import (
    OtpStatus,
    VerifyResult,
    can_resend,
    generate_otp,
    verify_otp,
)

logger = logging.getLogger(__name__)

__all__ = [
    "OtpStatus",
    "VerifyResult",
    "can_resend",
    "generate_otp",
    "request_otp",
    "verify_otp",
    "verify_otp_and_get_user",
    "verify_otp_and_issue_tokens",
]


def request_otp(phone: str) -> Channel:
    """Generate and dispatch an OTP for ``phone``, honoring the resend cooldown.

    Raises :class:`RateLimitedError` (``rate_limited``) if a cooldown is still
    active. Returns the channel the code was delivered over (T-004). In ``dev``
    the plaintext code is logged at INFO for manual QA (T-005 §2) — never in any
    other environment, and never persisted.
    """
    if not can_resend(phone):
        raise RateLimitedError(
            "An OTP was requested recently. Please wait before requesting another."
        )

    code = generate_otp(phone)

    if settings.DJANGO_ENV == "dev":
        logger.info("dev OTP for %s: %s", phone, code)

    return send_otp(phone, code)


def verify_otp_and_get_user(phone: str, code: str) -> User:
    """Verify ``code`` for ``phone`` and return the matching ``User``.

    On a correct code the ``User`` is fetched or created (new accounts default to
    the ``landlord`` role per the model default — the real role is chosen in
    EPIC-02, T-005 §15). Any non-success outcome (wrong / expired / exhausted)
    raises :class:`AuthInvalidError` (``auth_invalid``) — the endpoint never
    reveals which, to avoid leaking whether a code was ever issued.
    """
    result = verify_otp(phone, code)
    if result.status is not OtpStatus.SUCCESS:
        raise AuthInvalidError("The verification code is invalid or has expired.")

    user, _created = User.objects.get_or_create(phone=phone)
    return user


def verify_otp_and_issue_tokens(phone: str, code: str) -> tuple[User, dict[str, str]]:
    """Verify ``code``, fetch/create the ``User``, mint a JWT pair (T-006 §3).

    On success ``last_login_at`` is stamped (support/security visibility) and a
    fresh ``{access, refresh}`` pair carrying ``user_id`` + ``role`` claims is
    returned alongside the user. Failures propagate as :class:`AuthInvalidError`
    from :func:`verify_otp_and_get_user`.
    """
    user = verify_otp_and_get_user(phone, code)

    user.last_login_at = timezone.now()
    user.save(update_fields=["last_login_at"])

    tokens = issue_tokens(user)
    return user, tokens
