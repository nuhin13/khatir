"""API tests for the JWT lifecycle (T-006 §12).

Covers the full loop the mobile app relies on (T-006 §15 manual QA, automated):
verify-otp issues a pair with the right claims, ``/me`` is Bearer-protected,
``/refresh`` mints a new access token, and ``/logout`` blacklists a refresh
token so it can no longer refresh.

Tokens are minted directly via the service helper where the OTP dance is not the
thing under test, keeping each test focused on one behaviour.
"""

from __future__ import annotations

import pytest
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import AccessToken

from khatir.accounts.auth_tokens import issue_tokens
from khatir.accounts.models import User
from khatir.core.enums import Role

pytestmark = pytest.mark.django_db

PHONE = "+8801712345678"


@pytest.fixture
def client() -> APIClient:
    return APIClient()


@pytest.fixture
def user() -> User:
    return User.objects.create_user(phone=PHONE, name="Karim", role=Role.LANDLORD)


def _bearer(client: APIClient, access: str) -> None:
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")


# ── claims ──────────────────────────────────────────────────────────────────


def test_access_token_carries_user_id_and_role(user: User) -> None:
    tokens = issue_tokens(user)
    access = AccessToken(token=tokens["access"])  # type: ignore[arg-type]

    assert access["user_id"] == str(user.pk)
    assert access["role"] == Role.LANDLORD.value


# ── /me ───────────────────────────────────────────────────────────────────


def test_me_requires_auth(client: APIClient) -> None:
    resp = client.get(reverse("accounts:me"))

    assert resp.status_code == status.HTTP_401_UNAUTHORIZED
    assert resp.data["error"]["code"] == "auth_required"


def test_me_returns_user_with_token(client: APIClient, user: User) -> None:
    _bearer(client, issue_tokens(user)["access"])

    resp = client.get(reverse("accounts:me"))

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data == {
        "id": str(user.pk),
        "phone": PHONE,
        "role": Role.LANDLORD.value,
        "name": "Karim",
        "language": user.language,
    }


# ── /refresh ────────────────────────────────────────────────────────────────


def test_refresh_returns_new_access(client: APIClient, user: User) -> None:
    refresh = issue_tokens(user)["refresh"]

    resp = client.post(reverse("accounts:refresh"), {"refresh": refresh}, format="json")

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data["access"]
    # The new access token still authenticates /me.
    _bearer(client, resp.data["access"])
    me = client.get(reverse("accounts:me"))
    assert me.status_code == status.HTTP_200_OK


def test_refresh_rejects_garbage(client: APIClient) -> None:
    resp = client.post(reverse("accounts:refresh"), {"refresh": "not-a-token"}, format="json")

    assert resp.status_code == status.HTTP_401_UNAUTHORIZED
    assert resp.data["error"]["code"] == "auth_invalid"


# ── /logout ─────────────────────────────────────────────────────────────────


def test_logout_blacklists_refresh(client: APIClient, user: User) -> None:
    tokens = issue_tokens(user)
    _bearer(client, tokens["access"])

    logout = client.post(
        reverse("accounts:logout"), {"refresh": tokens["refresh"]}, format="json"
    )
    assert logout.status_code == status.HTTP_204_NO_CONTENT

    # The blacklisted refresh token can no longer mint an access token.
    client.credentials()  # drop the bearer header
    refresh = client.post(
        reverse("accounts:refresh"), {"refresh": tokens["refresh"]}, format="json"
    )
    assert refresh.status_code == status.HTTP_401_UNAUTHORIZED
    assert refresh.data["error"]["code"] == "auth_invalid"


def test_logout_requires_auth(client: APIClient, user: User) -> None:
    tokens = issue_tokens(user)

    resp = client.post(
        reverse("accounts:logout"), {"refresh": tokens["refresh"]}, format="json"
    )

    assert resp.status_code == status.HTTP_401_UNAUTHORIZED
    assert resp.data["error"]["code"] == "auth_required"
