"""JWT token issuance for OTP sign-in (T-006 §2, §15).

simplejwt mints the pair; we attach a ``role`` claim to the access token so
clients and permission checks can read it without an extra ``/me`` round-trip.
The database remains the source of truth on role change (T-006 §15) — the claim
is only a hint, never an authorization decision on its own.

``user_id`` is added by simplejwt itself via ``USER_ID_CLAIM`` (settings).
"""

from __future__ import annotations

from rest_framework_simplejwt.tokens import RefreshToken

from .models import User


def issue_tokens(user: User) -> dict[str, str]:
    """Return a freshly minted ``{access, refresh}`` pair for ``user``.

    The ``role`` claim is copied onto both the refresh token and the derived
    access token so the role travels with the access token clients actually use.
    """
    refresh = RefreshToken.for_user(user)
    refresh["role"] = user.role

    access = refresh.access_token
    access["role"] = user.role

    return {"access": str(access), "refresh": str(refresh)}
