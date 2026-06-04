"""Tests for the admin flag CRUD/toggle endpoints + /config/public flags dict.

Covers (task §11–§13): flag CRUD; toggle flips ``enabled`` + records actor +
audits + busts the public-flags cache; ``/config/public`` reflects the change
(<60s propagation); super+ops gate. Admin auth is the dedicated admin JWT realm.

Note: a data migration (T-004) seeds baseline flags into the test DB, so these
tests use unique non-seeded keys and assert *membership* rather than exact
equality of the global flags dict.
"""

from __future__ import annotations

import pytest
from django.core.cache import cache
from rest_framework.test import APIClient

from khatir.admin_portal.auth_tokens import issue_access_token
from khatir.admin_portal.models import AdminAuditEntry
from khatir.admin_portal.tests.factories import AdminUserFactory
from khatir.core.enums import AdminRole
from khatir.featureflags.enums import FlagScope
from khatir.featureflags.models import FeatureFlag
from khatir.featureflags.services import PUBLIC_FLAGS_CACHE_KEY
from khatir.featureflags.tests.factories import FeatureFlagFactory

FLAGS_URL = "/admin/api/flags"
CONFIG_PUBLIC_URL = "/api/v1/config/public"

pytestmark = pytest.mark.django_db


def _auth_client(role: str = AdminRole.OPS) -> APIClient:
    admin = AdminUserFactory(role=role)
    token, _ = issue_access_token(admin.pk, admin.role)
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    return client


@pytest.fixture(autouse=True)
def _clear_cache() -> None:
    cache.clear()


# --- CRUD --------------------------------------------------------------------


def test_create_flag() -> None:
    resp = _auth_client(AdminRole.SUPER).post(
        FLAGS_URL,
        {"key": "t002_new_flag", "description": "New flag", "scope": "global"},
        format="json",
    )
    assert resp.status_code == 201, resp.content
    body = resp.json()
    assert body["key"] == "t002_new_flag"
    assert body["enabled"] is False  # enabled is toggle-only
    flag = FeatureFlag.objects.get(key="t002_new_flag")
    assert flag.updated_by is not None


def test_list_flags() -> None:
    FeatureFlagFactory(key="t002_a")
    resp = _auth_client().get(FLAGS_URL)
    assert resp.status_code == 200
    body = resp.json()
    rows = body["results"] if isinstance(body, dict) else body
    keys = {row["key"] for row in rows}
    assert "t002_a" in keys


def test_retrieve_flag_by_key() -> None:
    flag = FeatureFlagFactory(key="t002_retrieve")
    resp = _auth_client().get(f"{FLAGS_URL}/{flag.key}")
    assert resp.status_code == 200
    assert resp.json()["key"] == "t002_retrieve"


def test_update_flag_description() -> None:
    flag = FeatureFlagFactory(key="t002_update", description="old")
    resp = _auth_client().patch(
        f"{FLAGS_URL}/{flag.key}",
        {"description": "new description"},
        format="json",
    )
    assert resp.status_code == 200
    flag.refresh_from_db()
    assert flag.description == "new description"
    # key is immutable even if supplied
    assert flag.key == "t002_update"


def test_update_cannot_change_enabled_directly() -> None:
    flag = FeatureFlagFactory(key="t002_enabled_guard", enabled=False)
    _auth_client().patch(f"{FLAGS_URL}/{flag.key}", {"enabled": True}, format="json")
    flag.refresh_from_db()
    assert flag.enabled is False  # read-only; only toggle flips it


# --- Toggle ------------------------------------------------------------------


def test_toggle_flips_enabled_and_records_actor() -> None:
    flag = FeatureFlagFactory(key="t002_toggle", enabled=False)
    client = _auth_client(AdminRole.SUPER)
    resp = client.patch(f"{FLAGS_URL}/{flag.key}/toggle")
    assert resp.status_code == 200
    assert resp.json()["enabled"] is True
    flag.refresh_from_db()
    assert flag.enabled is True
    assert flag.updated_by is not None
    # toggling again flips back
    resp = client.patch(f"{FLAGS_URL}/{flag.key}/toggle")
    assert resp.json()["enabled"] is False


def test_toggle_writes_audit_entry() -> None:
    flag = FeatureFlagFactory(key="t002_audit", enabled=False)
    _auth_client().patch(f"{FLAGS_URL}/{flag.key}/toggle")
    entry = (
        AdminAuditEntry.objects.filter(
            action="feature_flag.toggle", entity_id=str(flag.pk)
        )
        .order_by("-id")
        .first()
    )
    assert entry is not None
    assert entry.after_json == {"enabled": True}
    assert entry.before_json == {"enabled": False}


def test_toggle_busts_public_flags_cache() -> None:
    flag = FeatureFlagFactory(key="t002_cache", enabled=False)
    cache.set(PUBLIC_FLAGS_CACHE_KEY, {"t002_cache": False}, 60)
    _auth_client().patch(f"{FLAGS_URL}/{flag.key}/toggle")
    assert cache.get(PUBLIC_FLAGS_CACHE_KEY) is None


# --- /config/public integration ---------------------------------------------


def test_config_public_exposes_global_flags() -> None:
    FeatureFlagFactory(key="t002_pub_on", enabled=True, scope=FlagScope.GLOBAL)
    FeatureFlagFactory(key="t002_pub_off", enabled=False, scope=FlagScope.GLOBAL)
    flags = APIClient().get(CONFIG_PUBLIC_URL).json()["flags"]
    assert flags["t002_pub_on"] is True
    assert flags["t002_pub_off"] is False


def test_config_public_omits_non_global_flags() -> None:
    FeatureFlagFactory(key="t002_role_flag", enabled=True, scope=FlagScope.ROLE)
    FeatureFlagFactory(key="t002_user_flag", enabled=True, scope=FlagScope.USER)
    flags = APIClient().get(CONFIG_PUBLIC_URL).json()["flags"]
    assert "t002_role_flag" not in flags
    assert "t002_user_flag" not in flags


def test_toggle_reflects_in_config_public() -> None:
    flag = FeatureFlagFactory(
        key="t002_propagate", enabled=False, scope=FlagScope.GLOBAL
    )
    anon = APIClient()

    # Prime the public-config cache with the flag OFF.
    assert anon.get(CONFIG_PUBLIC_URL).json()["flags"]["t002_propagate"] is False

    # Admin toggles it ON; the cache must be busted so the next read flips.
    _auth_client(AdminRole.SUPER).patch(f"{FLAGS_URL}/{flag.key}/toggle")

    assert anon.get(CONFIG_PUBLIC_URL).json()["flags"]["t002_propagate"] is True


# --- Auth / role gate --------------------------------------------------------


def test_rejects_anonymous() -> None:
    assert APIClient().get(FLAGS_URL).status_code in (401, 403)


@pytest.mark.parametrize("role", [AdminRole.SUPER, AdminRole.OPS])
def test_platform_roles_allowed(role: str) -> None:
    assert _auth_client(role).get(FLAGS_URL).status_code == 200


@pytest.mark.parametrize(
    "role", [AdminRole.FINANCE, AdminRole.COMPLIANCE, AdminRole.SUPPORT]
)
def test_non_platform_roles_denied(role: str) -> None:
    flag = FeatureFlagFactory(key="t002_denied")
    client = _auth_client(role)
    assert client.get(FLAGS_URL).status_code == 403
    assert client.patch(f"{FLAGS_URL}/{flag.key}/toggle").status_code == 403
