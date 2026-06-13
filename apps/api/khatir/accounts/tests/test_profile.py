"""API tests for the profile endpoints (T-001 §12).

Exercises ``GET /api/v1/profile`` and ``PATCH /api/v1/profile`` through DRF's
``APIClient`` with a real authenticated user. Covers reads, per-field updates,
rejection of out-of-enum / non-self-selectable values, the self-only guarantee
(a user can never touch another user's row), and that updates write a
``profile.update`` audit entry with the changed before/after.
"""

from __future__ import annotations

import pytest
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient

from khatir.accounts.enums import Language, Role
from khatir.accounts.models import User
from khatir.core.models import AuditEntry

from .factories import UserFactory

pytestmark = pytest.mark.django_db

PROFILE_URL = "/api/v1/profile"


@pytest.fixture
def user() -> User:
    created: User = UserFactory(  # type: ignore[assignment]
        phone="+8801712345678",
        name="Original Name",
        role=Role.LANDLORD,
        language=Language.BN,
    )
    return created


@pytest.fixture
def client(user: User) -> APIClient:
    api = APIClient()
    api.force_authenticate(user=user)
    return api


def test_profile_url_resolves() -> None:
    assert reverse("profile:profile") == PROFILE_URL


# ── GET ───────────────────────────────────────────────────────────────────


def test_get_profile(client: APIClient, user: User) -> None:
    resp = client.get(PROFILE_URL)

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data == {
        "id": str(user.pk),
        "phone": user.phone,
        "name": "Original Name",
        "role": Role.LANDLORD.value,
        "language": Language.BN.value,
    }


def test_get_profile_requires_auth() -> None:
    resp = APIClient().get(PROFILE_URL)
    assert resp.status_code == status.HTTP_401_UNAUTHORIZED


# ── PATCH happy paths ───────────────────────────────────────────────────────


def test_update_name(client: APIClient, user: User) -> None:
    resp = client.patch(PROFILE_URL, {"name": "New Name"}, format="json")

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data["name"] == "New Name"
    user.refresh_from_db()
    assert user.name == "New Name"


def test_update_language(client: APIClient, user: User) -> None:
    resp = client.patch(PROFILE_URL, {"language": "en"}, format="json")

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data["language"] == "en"
    user.refresh_from_db()
    assert user.language == Language.EN


def test_update_role(client: APIClient, user: User) -> None:
    resp = client.patch(PROFILE_URL, {"role": "manager"}, format="json")

    assert resp.status_code == status.HTTP_200_OK
    assert resp.data["role"] == "manager"
    user.refresh_from_db()
    assert user.role == Role.MANAGER


def test_partial_update_leaves_other_fields(client: APIClient, user: User) -> None:
    resp = client.patch(PROFILE_URL, {"name": "Only Name"}, format="json")

    assert resp.status_code == status.HTTP_200_OK
    user.refresh_from_db()
    assert user.name == "Only Name"
    assert user.role == Role.LANDLORD  # untouched
    assert user.language == Language.BN  # untouched


# ── PATCH validation ────────────────────────────────────────────────────────


def test_invalid_role_rejected(client: APIClient, user: User) -> None:
    resp = client.patch(PROFILE_URL, {"role": "wizard"}, format="json")

    assert resp.status_code == status.HTTP_400_BAD_REQUEST
    assert resp.data["error"]["code"] == "validation_error"
    assert "role" in resp.data["error"]["details"]
    user.refresh_from_db()
    assert user.role == Role.LANDLORD


@pytest.mark.parametrize("role", ["caretaker", "admin"])
def test_non_self_selectable_role_rejected(
    client: APIClient, user: User, role: str
) -> None:
    """caretaker/admin are assigned, never self-chosen (T-001 §2)."""
    resp = client.patch(PROFILE_URL, {"role": role}, format="json")

    assert resp.status_code == status.HTTP_400_BAD_REQUEST
    assert resp.data["error"]["code"] == "validation_error"
    assert "role" in resp.data["error"]["details"]
    user.refresh_from_db()
    assert user.role == Role.LANDLORD


def test_invalid_language_rejected(client: APIClient, user: User) -> None:
    resp = client.patch(PROFILE_URL, {"language": "fr"}, format="json")

    assert resp.status_code == status.HTTP_400_BAD_REQUEST
    assert resp.data["error"]["code"] == "validation_error"
    assert "language" in resp.data["error"]["details"]
    user.refresh_from_db()
    assert user.language == Language.BN


def test_empty_patch_rejected(client: APIClient) -> None:
    resp = client.patch(PROFILE_URL, {}, format="json")

    assert resp.status_code == status.HTTP_400_BAD_REQUEST
    assert resp.data["error"]["code"] == "validation_error"


# ── self-only ───────────────────────────────────────────────────────────────


def test_cannot_update_other_user(client: APIClient, user: User) -> None:
    """The endpoint only ever writes the authenticated user's row.

    There is no path parameter to address another user; passing an ``id`` in the
    body is ignored (it is read-only) and the caller's own row is what changes.
    """
    other: User = UserFactory(  # type: ignore[assignment]
        phone="+8801799999999", name="Other", role=Role.TENANT
    )

    resp = client.patch(
        PROFILE_URL,
        {"id": str(other.pk), "name": "Hijacked"},
        format="json",
    )

    assert resp.status_code == status.HTTP_200_OK
    other.refresh_from_db()
    user.refresh_from_db()
    assert other.name == "Other"  # untouched
    assert user.name == "Hijacked"  # the caller's own row changed


# ── audit ────────────────────────────────────────────────────────────────────


def test_update_writes_audit(client: APIClient, user: User) -> None:
    client.patch(PROFILE_URL, {"role": "manager"}, format="json")

    entry = AuditEntry.objects.get(action="profile.update")
    assert entry.actor_id == user.pk
    assert entry.target_type == "accounts.user"
    assert entry.target_id == str(user.pk)
    assert entry.before == {"role": Role.LANDLORD.value}
    assert entry.after == {"role": Role.MANAGER.value}


def test_no_op_update_skips_audit(client: APIClient, user: User) -> None:
    """Patching a field to its current value changes nothing and audits nothing."""
    resp = client.patch(PROFILE_URL, {"name": "Original Name"}, format="json")

    assert resp.status_code == status.HTTP_200_OK
    assert not AuditEntry.objects.filter(action="profile.update").exists()
