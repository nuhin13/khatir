"""DRF permission classes for the admin portal — EPIC-11.T-004.

Admin-portal authorization is **completely separate** from the customer-facing
permission layer in :mod:`khatir.core.permissions`. Customer permissions read
``request.user.role`` (a customer ``accounts.User``); the classes here never
touch ``request.user`` at all. They validate a *dedicated* admin JWT — signed
with ``settings.ADMIN_JWT_SIGNING_KEY`` (never the customer signing key) — and
gate access purely on the staff member's :class:`~khatir.core.enums.AdminRole`.

Admin JWT contract (settings & task §15)
----------------------------------------
The admin login flow (T-003) issues a self-contained HS256 token whose payload
carries at minimum::

    {"admin_user_id": <int>, "role": "<AdminRole value>", ...}

These classes decode that token from the ``Authorization: Bearer <jwt>`` header
with PyJWT, verify the signature/expiry against ``ADMIN_JWT_SIGNING_KEY``, and
expose the decoded principal on ``request.admin_principal`` for downstream code.
A missing/invalid/expired token, or a payload missing a recognised role, denies
access — it never falls through to the customer JWT.

Role → section matrix (task §2)
-------------------------------
Each :class:`AdminSection` lists the roles allowed to reach it. ``super`` is
allowed everywhere; the rest are scoped:

===========  ===============================================================
Section      Allowed roles
===========  ===============================================================
users        super, ops, support (support is read-only — enforce at the view)
platform     super, ops
billing      super, finance
pricing      super, finance
audit        super, compliance
export       super, compliance
===========  ===============================================================

Usage
-----
Gate an endpoint by the roles it requires (compose with DRF ``&`` / ``|``)::

    from khatir.admin_portal.permissions import IsAdminUser, RequiresAdminRole
    from khatir.core.enums import AdminRole

    class FeatureFlagViewSet(ModelViewSet):
        permission_classes = [RequiresAdminRole(AdminRole.SUPER, AdminRole.OPS)]

Or gate by a logical section, which expands to the matrix above::

    permission_classes = [RequiresAdminSection(AdminSection.BILLING)]

``IsAdminUser`` only checks that a valid admin token is present (any role);
combine it with a role/section class when an endpoint is role-restricted.
"""

from __future__ import annotations

from typing import Any, ClassVar

import jwt
from django.conf import settings
from rest_framework.permissions import BasePermission
from rest_framework.request import Request

from khatir.core.enums import AdminRole

# ── Role constants (re-exported for call sites that prefer module-level names) ──
SUPER = AdminRole.SUPER
OPS = AdminRole.OPS
FINANCE = AdminRole.FINANCE
COMPLIANCE = AdminRole.COMPLIANCE
SUPPORT = AdminRole.SUPPORT

#: The set of every valid admin role value.
ALL_ROLES: frozenset[str] = frozenset(r.value for r in AdminRole)


class AdminSection:
    """Logical admin-portal sections, each mapped to the roles allowed in it.

    ``super`` is implicitly allowed in every section (see :data:`SECTION_ROLES`).
    Sections that are *read-only* for a given role (e.g. ``support`` on
    ``users``) are still listed here — read/write granularity is enforced at the
    view layer (e.g. ``SAFE_METHODS`` checks), not by these constants.
    """

    USERS = "users"
    PLATFORM = "platform"
    BILLING = "billing"
    PRICING = "pricing"
    AUDIT = "audit"
    EXPORT = "export"


#: Section → roles allowed to access it. ``super`` is added to every entry.
SECTION_ROLES: dict[str, frozenset[str]] = {
    AdminSection.USERS: frozenset({SUPER, OPS, SUPPORT}),
    AdminSection.PLATFORM: frozenset({SUPER, OPS}),
    AdminSection.BILLING: frozenset({SUPER, FINANCE}),
    AdminSection.PRICING: frozenset({SUPER, FINANCE}),
    AdminSection.AUDIT: frozenset({SUPER, COMPLIANCE}),
    AdminSection.EXPORT: frozenset({SUPER, COMPLIANCE}),
}


class AdminPrincipal:
    """The decoded, verified identity of an admin from a validated admin JWT.

    Deliberately *not* a Django auth user: it is attached to
    ``request.admin_principal`` and is the single source of truth for admin
    authorization. ``role`` is read from the verified token claim.
    """

    __slots__ = ("admin_user_id", "role", "claims")

    def __init__(self, admin_user_id: Any, role: str, claims: dict[str, Any]) -> None:
        self.admin_user_id = admin_user_id
        self.role = role
        self.claims = claims

    def __repr__(self) -> str:  # pragma: no cover - debug aid
        return f"AdminPrincipal(admin_user_id={self.admin_user_id!r}, role={self.role!r})"


def _decode_admin_principal(request: Request) -> AdminPrincipal | None:
    """Return the verified :class:`AdminPrincipal`, or ``None`` if absent/invalid.

    Reads ``Authorization: Bearer <jwt>``, verifies the HS256 signature and
    expiry against ``settings.ADMIN_JWT_SIGNING_KEY``, and requires the payload
    to carry an ``admin_user_id`` and a recognised ``role``. The result is
    memoised on the request so multiple permission classes decode only once.
    """
    cached: AdminPrincipal | None = getattr(request, "admin_principal", None)
    if cached is not None:
        return cached
    # ``False`` sentinel distinguishes "already tried, failed" from "not tried".
    if getattr(request, "_admin_principal_checked", False):
        return None

    request._admin_principal_checked = True  # type: ignore[attr-defined]

    header = request.META.get("HTTP_AUTHORIZATION", "")
    parts = header.split()
    if len(parts) == 2 and parts[0].lower() == "bearer":
        token = parts[1]
    else:
        # Fall back to the HTTP-only session cookie set by the Next.js frontend.
        token = request.COOKIES.get("khatir_admin_session", "")
    if not token:
        return None

    try:
        claims = jwt.decode(
            token,
            settings.ADMIN_JWT_SIGNING_KEY,
            algorithms=["HS256"],
        )
    except jwt.PyJWTError:
        return None

    admin_user_id = claims.get("admin_user_id") or claims.get("sub")
    role = claims.get("role")
    if admin_user_id is None or role not in ALL_ROLES:
        return None

    principal = AdminPrincipal(admin_user_id=admin_user_id, role=role, claims=claims)
    request.admin_principal = principal  # type: ignore[attr-defined]
    return principal


class IsAdminUser(BasePermission):
    """Request must carry a valid admin JWT (any :class:`AdminRole`).

    Validates the dedicated admin token and attaches the decoded
    :class:`AdminPrincipal` to ``request.admin_principal``. Does **not** gate on
    a specific role — compose with :func:`RequiresAdminRole` /
    :func:`RequiresAdminSection` for role-restricted endpoints.
    """

    def has_permission(self, request: Request, view: Any) -> bool:
        return _decode_admin_principal(request) is not None


class _RequiresAdminRole(IsAdminUser):
    """Base for role-gated admin permissions; subclasses set ``required_roles``."""

    required_roles: ClassVar[frozenset[str]] = frozenset()

    def has_permission(self, request: Request, view: Any) -> bool:
        principal = _decode_admin_principal(request)
        if principal is None:
            return False
        # ``super`` is allowed everywhere.
        if principal.role == SUPER:
            return True
        return principal.role in self.required_roles


def RequiresAdminRole(*roles: str) -> type[_RequiresAdminRole]:  # noqa: N802 - DRF CapWords
    """Permission class allowing any admin whose role is in ``roles`` (or ``super``).

    ``super`` is always allowed regardless of ``roles``. The returned class
    composes with DRF ``&`` / ``|`` like any other permission::

        permission_classes = [RequiresAdminRole(AdminRole.FINANCE)]
    """
    allowed = frozenset(str(r) for r in roles) | {SUPER}
    label = "_".join(sorted(allowed)) or "Any"

    class _Gate(_RequiresAdminRole):
        required_roles = allowed

    _Gate.__name__ = f"RequiresAdminRole_{label}"
    _Gate.__qualname__ = _Gate.__name__
    return _Gate


def RequiresAdminSection(section: str) -> type[_RequiresAdminRole]:  # noqa: N802 - DRF CapWords
    """Permission class gating on a logical :class:`AdminSection`.

    Expands ``section`` to the roles in :data:`SECTION_ROLES` (``super`` always
    included) and behaves exactly like :func:`RequiresAdminRole` for them::

        permission_classes = [RequiresAdminSection(AdminSection.AUDIT)]
    """
    try:
        roles = SECTION_ROLES[section]
    except KeyError as exc:  # pragma: no cover - programmer error
        raise ValueError(f"Unknown admin section: {section!r}") from exc
    gate = RequiresAdminRole(*roles)
    gate.__name__ = f"RequiresAdminSection_{section}"
    gate.__qualname__ = gate.__name__
    return gate
