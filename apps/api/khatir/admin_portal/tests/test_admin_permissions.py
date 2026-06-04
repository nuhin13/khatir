"""Tests for admin-portal DRF permission classes (T-004 §12).

Covers: ``IsAdminUser`` token validation (missing / malformed / wrong-key /
expired / unknown-role) and the parametrized role × section matrix for
``RequiresAdminRole`` / ``RequiresAdminSection`` (including the ``super``
allow-all rule). All admin auth here is fully separate from the customer JWT.
"""

from __future__ import annotations

import datetime as dt
from typing import Any

import jwt
import pytest
from django.conf import settings
from rest_framework.test import APIRequestFactory

from khatir.admin_portal.permissions import (
    SECTION_ROLES,
    AdminSection,
    IsAdminUser,
    RequiresAdminRole,
    RequiresAdminSection,
)
from khatir.core.enums import AdminRole, Role

_FACTORY = APIRequestFactory()


def _mint(
    *,
    admin_user_id: Any = 42,
    role: str | None = AdminRole.OPS,
    key: str | None = None,
    expired: bool = False,
    extra: dict[str, Any] | None = None,
) -> str:
    """Return a signed admin JWT for the given claims."""
    payload: dict[str, Any] = {"admin_user_id": admin_user_id}
    if role is not None:
        payload["role"] = role
    if expired:
        payload["exp"] = dt.datetime.now(tz=dt.UTC) - dt.timedelta(minutes=1)
    if extra:
        payload.update(extra)
    return jwt.encode(payload, key or settings.ADMIN_JWT_SIGNING_KEY, algorithm="HS256")


def _request(token: str | None = None):
    headers = {}
    if token is not None:
        headers["HTTP_AUTHORIZATION"] = f"Bearer {token}"
    return _FACTORY.get("/admin/whatever", **headers)


# --- IsAdminUser: token validation -----------------------------------------


def test_is_admin_user_accepts_valid_token():
    req = _request(_mint())
    assert IsAdminUser().has_permission(req, view=None) is True


def test_is_admin_user_rejects_missing_header():
    assert IsAdminUser().has_permission(_request(), view=None) is False


def test_is_admin_user_rejects_malformed_header():
    req = _FACTORY.get("/admin/x", HTTP_AUTHORIZATION="Token abc")
    assert IsAdminUser().has_permission(req, view=None) is False


def test_is_admin_user_rejects_wrong_signing_key():
    req = _request(_mint(key="someone-elses-key"))
    assert IsAdminUser().has_permission(req, view=None) is False


def test_is_admin_user_rejects_expired_token():
    req = _request(_mint(expired=True))
    assert IsAdminUser().has_permission(req, view=None) is False


def test_is_admin_user_rejects_unknown_role():
    req = _request(_mint(role="emperor"))
    assert IsAdminUser().has_permission(req, view=None) is False


def test_is_admin_user_rejects_customer_role_value():
    # A customer JWT-style role must never satisfy the admin layer.
    req = _request(_mint(role=Role.LANDLORD))
    assert IsAdminUser().has_permission(req, view=None) is False


def test_is_admin_user_rejects_missing_admin_user_id():
    req = _request(_mint(admin_user_id=None))
    assert IsAdminUser().has_permission(req, view=None) is False


def test_valid_token_attaches_principal():
    perm = IsAdminUser()
    req = _request(_mint(admin_user_id=7, role=AdminRole.FINANCE))
    assert perm.has_permission(req, view=None) is True
    assert req.admin_principal.admin_user_id == 7
    assert req.admin_principal.role == AdminRole.FINANCE


# --- Role matrix -------------------------------------------------------------

# (section, role, expected_allowed) for every role × section combination.
_MATRIX_CASES = [
    (section, role, (role == AdminRole.SUPER or role in allowed))
    for section, allowed in SECTION_ROLES.items()
    for role in AdminRole.values
]


@pytest.mark.parametrize(("section", "role", "allowed"), _MATRIX_CASES)
def test_role_matrix(section: str, role: str, allowed: bool):
    perm = RequiresAdminSection(section)()
    req = _request(_mint(role=role))
    assert perm.has_permission(req, view=None) is allowed


def test_super_allowed_in_every_section():
    for section in SECTION_ROLES:
        perm = RequiresAdminSection(section)()
        req = _request(_mint(role=AdminRole.SUPER))
        assert perm.has_permission(req, view=None) is True


def test_requires_admin_role_super_always_allowed():
    # Even when not listed, super passes.
    perm = RequiresAdminRole(AdminRole.FINANCE)()
    req = _request(_mint(role=AdminRole.SUPER))
    assert perm.has_permission(req, view=None) is True


def test_requires_admin_role_denies_unlisted_role():
    perm = RequiresAdminRole(AdminRole.FINANCE)()
    req = _request(_mint(role=AdminRole.SUPPORT))
    assert perm.has_permission(req, view=None) is False


def test_requires_admin_role_allows_listed_role():
    perm = RequiresAdminRole(AdminRole.FINANCE)()
    req = _request(_mint(role=AdminRole.FINANCE))
    assert perm.has_permission(req, view=None) is True


def test_role_gate_denies_unauthenticated():
    perm = RequiresAdminRole(AdminRole.OPS)()
    assert perm.has_permission(_request(), view=None) is False


def test_unknown_section_raises():
    with pytest.raises(ValueError, match="Unknown admin section"):
        RequiresAdminSection("nonexistent")


# --- Specific matrix expectations from task §2 ------------------------------


def test_finance_blocked_from_audit():
    perm = RequiresAdminSection(AdminSection.AUDIT)()
    req = _request(_mint(role=AdminRole.FINANCE))
    assert perm.has_permission(req, view=None) is False


def test_compliance_blocked_from_billing():
    perm = RequiresAdminSection(AdminSection.BILLING)()
    req = _request(_mint(role=AdminRole.COMPLIANCE))
    assert perm.has_permission(req, view=None) is False


def test_support_allowed_in_users_section():
    perm = RequiresAdminSection(AdminSection.USERS)()
    req = _request(_mint(role=AdminRole.SUPPORT))
    assert perm.has_permission(req, view=None) is True


def test_support_blocked_from_platform():
    perm = RequiresAdminSection(AdminSection.PLATFORM)()
    req = _request(_mint(role=AdminRole.SUPPORT))
    assert perm.has_permission(req, view=None) is False
