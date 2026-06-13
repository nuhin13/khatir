"""API + service tests for the admin auth flow (T-003 §12).

Exercises login (happy, wrong password, disabled, unknown email), the MFA
challenge → verify-mfa flow (happy, wrong code), logout (token revoked), me,
the separate-signing-key guarantee, and the login rate-limit — all through
DRF's ``APIClient`` against the real services, tokens, and audit log
(``settings.test`` LocMem cache, cleared between tests by ``conftest``).

Error bodies use the standard envelope ``{"error": {"code", "message", ...}}``;
auth failures are intentionally uniform (``auth_invalid``) so they never reveal
which factor failed.
"""

from __future__ import annotations

from collections.abc import Iterator

import pyotp
import pytest
from django.test import override_settings
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient

from khatir.admin_portal.auth_tokens import decode_access_token
from khatir.admin_portal.models import AdminAuditEntry, AdminUser
from khatir.admin_portal.tests.factories import AdminUserFactory
from khatir.core.encryption import encrypt

pytestmark = pytest.mark.django_db

PASSWORD = "testpassword123"  # the AdminUserFactory password
TOTP_SECRET = pyotp.random_base32()


@pytest.fixture
def client() -> APIClient:
    return APIClient()


@pytest.fixture
def admin_no_mfa() -> AdminUser:
    """A staff account with no TOTP secret (logs in directly)."""
    return AdminUserFactory()


@pytest.fixture
def admin_with_mfa() -> AdminUser:
    """A staff account with a configured (encrypted) TOTP secret."""
    return AdminUserFactory(totp_secret_enc=encrypt(TOTP_SECRET))


def _login(client: APIClient, email: str, password: str) -> object:
    return client.post(reverse("admin_portal:login"), {"email": email, "password": password})


# ── login (no MFA) ─────────────────────────────────────────────────────────


def test_login_success_no_mfa_issues_token(client: APIClient, admin_no_mfa: AdminUser) -> None:
    resp = _login(client, admin_no_mfa.email, PASSWORD)
    assert resp.status_code == status.HTTP_200_OK
    body = resp.json()
    assert body["mfa_required"] is False
    assert body["access"]
    assert body["admin"]["email"] == admin_no_mfa.email
    # last_login_at stamped + a login_success audit row written.
    admin_no_mfa.refresh_from_db()
    assert admin_no_mfa.last_login_at is not None
    assert AdminAuditEntry.objects.filter(action="admin_auth.login_success").count() == 1


def test_wrong_password(client: APIClient, admin_no_mfa: AdminUser) -> None:
    resp = _login(client, admin_no_mfa.email, "wrong-password")
    assert resp.status_code == status.HTTP_401_UNAUTHORIZED
    assert resp.json()["error"]["code"] == "auth_invalid"
    assert AdminAuditEntry.objects.filter(action="admin_auth.login_failed").count() == 1


def test_unknown_email(client: APIClient) -> None:
    resp = _login(client, "nobody@khatir.io", PASSWORD)
    assert resp.status_code == status.HTTP_401_UNAUTHORIZED
    assert resp.json()["error"]["code"] == "auth_invalid"


def test_disabled_account_blocked(client: APIClient) -> None:
    admin = AdminUserFactory(disabled=True)
    resp = _login(client, admin.email, PASSWORD)
    assert resp.status_code == status.HTTP_401_UNAUTHORIZED
    assert resp.json()["error"]["code"] == "auth_invalid"
    assert AdminAuditEntry.objects.filter(
        action="admin_auth.login_failed", reason="account disabled"
    ).exists()


# ── login → MFA challenge → verify-mfa ──────────────────────────────────────


def test_login_with_mfa_returns_challenge(client: APIClient, admin_with_mfa: AdminUser) -> None:
    resp = _login(client, admin_with_mfa.email, PASSWORD)
    assert resp.status_code == status.HTTP_200_OK
    body = resp.json()
    assert body["mfa_required"] is True
    assert body["mfa_token"]
    assert "access" not in body
    assert AdminAuditEntry.objects.filter(action="admin_auth.mfa_challenged").exists()


def test_verify_mfa_success(client: APIClient, admin_with_mfa: AdminUser) -> None:
    challenge = _login(client, admin_with_mfa.email, PASSWORD).json()["mfa_token"]
    code = pyotp.TOTP(TOTP_SECRET).now()
    resp = client.post(
        reverse("admin_portal:verify-mfa"), {"mfa_token": challenge, "code": code}
    )
    assert resp.status_code == status.HTTP_200_OK
    body = resp.json()
    assert body["access"]
    assert body["session_timeout_minutes"] == 60
    assert AdminAuditEntry.objects.filter(action="admin_auth.login_success").exists()


def test_mfa_wrong_code(client: APIClient, admin_with_mfa: AdminUser) -> None:
    challenge = _login(client, admin_with_mfa.email, PASSWORD).json()["mfa_token"]
    resp = client.post(
        reverse("admin_portal:verify-mfa"), {"mfa_token": challenge, "code": "000000"}
    )
    assert resp.status_code == status.HTTP_401_UNAUTHORIZED
    assert resp.json()["error"]["code"] == "auth_invalid"
    assert AdminAuditEntry.objects.filter(action="admin_auth.mfa_failed").exists()


def test_verify_mfa_bad_challenge_token(client: APIClient) -> None:
    resp = client.post(
        reverse("admin_portal:verify-mfa"), {"mfa_token": "not-a-jwt", "code": "000000"}
    )
    assert resp.status_code == status.HTTP_401_UNAUTHORIZED
    assert resp.json()["error"]["code"] == "auth_invalid"


# ── me + logout ──────────────────────────────────────────────────────────


def _auth_client(admin_no_mfa: AdminUser) -> tuple[APIClient, str]:
    client = APIClient()
    token = _login(client, admin_no_mfa.email, PASSWORD).json()["access"]
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    return client, token


def test_me_requires_admin_token(client: APIClient) -> None:
    resp = client.get(reverse("admin_portal:me"))
    assert resp.status_code in (status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN)


def test_me_returns_admin(admin_no_mfa: AdminUser) -> None:
    client, _ = _auth_client(admin_no_mfa)
    resp = client.get(reverse("admin_portal:me"))
    assert resp.status_code == status.HTTP_200_OK
    assert resp.json()["email"] == admin_no_mfa.email
    assert "password_hash" not in resp.json()
    assert "totp_secret_enc" not in resp.json()


def test_logout_revokes_token(admin_no_mfa: AdminUser) -> None:
    client, token = _auth_client(admin_no_mfa)
    resp = client.post(reverse("admin_portal:logout"))
    assert resp.status_code == status.HTTP_204_NO_CONTENT
    assert AdminAuditEntry.objects.filter(action="admin_auth.logout").exists()
    # The same token is now rejected on a protected endpoint.
    resp2 = client.get(reverse("admin_portal:me"))
    assert resp2.status_code == status.HTTP_401_UNAUTHORIZED


def test_disabled_after_login_blocks_token(admin_no_mfa: AdminUser) -> None:
    client, _ = _auth_client(admin_no_mfa)
    admin_no_mfa.disabled = True
    admin_no_mfa.save(update_fields=["disabled", "updated_at"])
    resp = client.get(reverse("admin_portal:me"))
    assert resp.status_code == status.HTTP_401_UNAUTHORIZED


# ── separate signing key ────────────────────────────────────────────────


def test_admin_token_signed_with_separate_key(admin_no_mfa: AdminUser) -> None:
    from django.conf import settings

    assert settings.ADMIN_JWT_SIGNING_KEY != settings.SIMPLE_JWT["SIGNING_KEY"]
    _, token = _auth_client(admin_no_mfa)
    # Decodes under the admin key...
    payload = decode_access_token(token)
    assert payload["sub"] == str(admin_no_mfa.pk)
    assert payload["role"] == admin_no_mfa.role
    # ...but NOT under the customer JWT key.
    import jwt

    with pytest.raises(jwt.PyJWTError):
        jwt.decode(token, settings.SIMPLE_JWT["SIGNING_KEY"], algorithms=["HS256"])


# ── mfa_required config respected ────────────────────────────────────────


@override_settings(ADMIN_MFA_REQUIRED=False)
def test_mfa_not_required_when_flag_off(client: APIClient, admin_with_mfa: AdminUser) -> None:
    resp = _login(client, admin_with_mfa.email, PASSWORD)
    assert resp.status_code == status.HTTP_200_OK
    body = resp.json()
    assert body["mfa_required"] is False
    assert body["access"]


# ── rate limit ───────────────────────────────────────────────────────────


@pytest.fixture
def tight_login_limit() -> Iterator[None]:
    with override_settings(
        REST_FRAMEWORK={
            **__import__("django.conf", fromlist=["settings"]).settings.REST_FRAMEWORK,
            "DEFAULT_THROTTLE_RATES": {
                "admin_login_email": "2/min",
                "admin_login_ip": "100/min",
                "admin_mfa_ip": "100/min",
            },
        }
    ):
        yield


def test_rate_limit_on_login(
    client: APIClient, admin_no_mfa: AdminUser, tight_login_limit: None
) -> None:
    # Two wrong attempts are allowed, the third on the same email is throttled.
    assert _login(client, admin_no_mfa.email, "x").status_code == status.HTTP_401_UNAUTHORIZED
    assert _login(client, admin_no_mfa.email, "x").status_code == status.HTTP_401_UNAUTHORIZED
    resp = _login(client, admin_no_mfa.email, "x")
    assert resp.status_code == status.HTTP_429_TOO_MANY_REQUESTS
    assert resp.json()["error"]["code"] == "rate_limited"
