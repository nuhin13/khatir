"""DRF authentication + permission for the admin portal — EPIC-11.T-003.

``AdminJWTAuthentication`` reads a ``Bearer`` admin access token, validates it
against the dedicated admin signing key, loads the :class:`AdminUser`, and
attaches it to ``request.admin_user``. It deliberately does **not** populate
``request.user`` — staff are not customer ``User`` rows, and conflating the two
realms is exactly what this separation prevents.

``IsAdminAuthenticated`` gates admin-only endpoints on the presence of a valid,
non-disabled ``request.admin_user``.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

from rest_framework import authentication
from rest_framework.permissions import BasePermission
from rest_framework.request import Request

from khatir.core.exceptions import AuthInvalidError

from .auth_tokens import AdminTokenError, decode_access_token
from .models import AdminUser

if TYPE_CHECKING:
    from rest_framework.views import APIView

_HEADER_PREFIX = "Bearer"


class AdminJWTAuthentication(authentication.BaseAuthentication):
    """Authenticate an admin via a ``Bearer`` admin access token.

    Returns ``None`` (not an error) when no admin Authorization header is
    present, so ``AllowAny`` endpoints still work; raises ``AuthInvalidError``
    only when a token *is* supplied but is invalid/expired/revoked or the
    backing account is missing or disabled.
    """

    keyword = _HEADER_PREFIX

    def authenticate(self, request: Request) -> tuple[None, AdminUser] | None:
        header = authentication.get_authorization_header(request).decode("latin-1")
        if not header:
            return None
        parts = header.split()
        if parts[0] != self.keyword:
            return None
        if len(parts) != 2:
            raise AuthInvalidError("Malformed admin Authorization header.")

        try:
            payload = decode_access_token(parts[1])
        except AdminTokenError as exc:
            raise AuthInvalidError("The admin token is invalid or expired.") from exc

        try:
            admin_user = AdminUser.objects.get(pk=int(payload["sub"]))
        except (AdminUser.DoesNotExist, ValueError, KeyError) as exc:
            raise AuthInvalidError("The admin account no longer exists.") from exc

        if admin_user.disabled:
            raise AuthInvalidError("This admin account is disabled.")

        # DRF expects ``(user, auth)``; we keep request.user untouched (no
        # customer User) and stash the admin on request.admin_user via the
        # auth slot, which DRF assigns to ``request.auth``.
        request.admin_user = admin_user  # type: ignore[attr-defined]
        return (None, admin_user)

    def authenticate_header(self, request: Request) -> str:
        return self.keyword


class IsAdminAuthenticated(BasePermission):
    """Allow only requests carrying a valid, non-disabled admin account."""

    def has_permission(self, request: Request, view: APIView) -> bool:
        admin_user = getattr(request, "admin_user", None)
        return isinstance(admin_user, AdminUser) and not admin_user.disabled
