"""Tests for the kill-switch endpoints — EPIC-13.T-003.

Covers (task §11–§13): list the 5 named switches; toggle requires a fresh MFA
re-confirmation + a reason; wrong/absent MFA is blocked; an immutable
:class:`KillSwitchEvent` is recorded; the public-config cache is busted (instant
propagation); super only. Admin auth is the dedicated admin JWT realm.
"""

from __future__ import annotations

import pyotp
import pytest
from django.core.cache import cache
from rest_framework.test import APIClient

from khatir.admin_portal.auth_tokens import issue_access_token
from khatir.admin_portal.models import AdminAuditEntry
from khatir.admin_portal.tests.factories import AdminUserFactory
from khatir.core.encryption import encrypt
from khatir.core.enums import AdminRole
from khatir.featureflags.enums import FlagScope, KillSwitchAction
from khatir.featureflags.models import FeatureFlag, KillSwitchEvent
from khatir.featureflags.services import PUBLIC_FLAGS_CACHE_KEY
from khatir.featureflags.tests.factories import FeatureFlagFactory

KILL_URL = "/admin/api/killswitches"
CONFIG_PUBLIC_URL = "/api/v1/config/public"

TOTP_SECRET = pyotp.random_base32()

pytestmark = pytest.mark.django_db


def _valid_code() -> str:
    return pyotp.TOTP(TOTP_SECRET).now()


def _super_with_mfa() -> object:
    """A super admin with a configured (encrypted) TOTP secret."""
    return AdminUserFactory(
        role=AdminRole.SUPER, totp_secret_enc=encrypt(TOTP_SECRET)
    )


def _client(admin: object) -> APIClient:
    token, _ = issue_access_token(admin.pk, admin.role)  # type: ignore[attr-defined]
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    return client


def _seed_switch(key: str = "warnings_feature", enabled: bool = True) -> FeatureFlag:
    return FeatureFlagFactory(key=key, enabled=enabled, scope=FlagScope.GLOBAL)


@pytest.fixture(autouse=True)
def _clear_cache() -> None:
    cache.clear()


# --- List --------------------------------------------------------------------


def test_list_returns_named_switches_in_order() -> None:
    for key in ("master_kill_switch", "warnings_feature", "reviews_feature"):
        _seed_switch(key)
    resp = _client(_super_with_mfa()).get(KILL_URL)
    assert resp.status_code == 200, resp.content
    keys = [row["key"] for row in resp.json()]
    # canonical order: warnings before reviews before master.
    assert keys == ["warnings_feature", "reviews_feature", "master_kill_switch"]


# --- Toggle: MFA -------------------------------------------------------------


def test_toggle_requires_mfa_valid_code_kills_feature() -> None:
    flag = _seed_switch("warnings_feature", enabled=True)
    resp = _client(_super_with_mfa()).post(
        f"{KILL_URL}/{flag.key}/toggle",
        {"mfa_code": _valid_code(), "reason": "Abuse incident #42"},
        format="json",
    )
    assert resp.status_code == 200, resp.content
    assert resp.json()["enabled"] is False
    flag.refresh_from_db()
    assert flag.enabled is False


def test_wrong_mfa_blocked() -> None:
    flag = _seed_switch("warnings_feature", enabled=True)
    resp = _client(_super_with_mfa()).post(
        f"{KILL_URL}/{flag.key}/toggle",
        {"mfa_code": "000000", "reason": "Abuse incident #42"},
        format="json",
    )
    assert resp.status_code == 403, resp.content
    flag.refresh_from_db()
    assert flag.enabled is True  # unchanged
    assert not KillSwitchEvent.objects.filter(switch_key=flag.key).exists()


def test_no_reason_blocked() -> None:
    flag = _seed_switch("warnings_feature", enabled=True)
    resp = _client(_super_with_mfa()).post(
        f"{KILL_URL}/{flag.key}/toggle",
        {"mfa_code": _valid_code()},
        format="json",
    )
    assert resp.status_code == 400, resp.content
    flag.refresh_from_db()
    assert flag.enabled is True  # unchanged


# --- Toggle: event + propagation ---------------------------------------------


def test_event_created_immutable_with_actor() -> None:
    flag = _seed_switch("reviews_feature", enabled=True)
    admin = _super_with_mfa()
    _client(admin).post(
        f"{KILL_URL}/{flag.key}/toggle",
        {
            "mfa_code": _valid_code(),
            "reason": "Court order",
            "lawyer_reference": "JIRA-LEGAL-7",
        },
        format="json",
    )
    event = KillSwitchEvent.objects.get(switch_key=flag.key)
    assert event.action == KillSwitchAction.DISABLE  # killing a live feature
    assert event.reason == "Court order"
    assert event.lawyer_reference == "JIRA-LEGAL-7"
    assert event.admin_user_id == admin.pk  # type: ignore[attr-defined]
    # immutable: updates are blocked.
    with pytest.raises(TypeError):
        event.reason = "tampered"
        event.save()


def test_enable_action_when_restoring() -> None:
    flag = _seed_switch("free_text_feature", enabled=False)  # already killed
    _client(_super_with_mfa()).post(
        f"{KILL_URL}/{flag.key}/toggle",
        {"mfa_code": _valid_code(), "reason": "Resolved; restoring"},
        format="json",
    )
    event = KillSwitchEvent.objects.get(switch_key=flag.key)
    assert event.action == KillSwitchAction.ENABLE
    flag.refresh_from_db()
    assert flag.enabled is True


def test_toggle_writes_admin_audit_entry() -> None:
    flag = _seed_switch("history_flags_feature", enabled=True)
    _client(_super_with_mfa()).post(
        f"{KILL_URL}/{flag.key}/toggle",
        {"mfa_code": _valid_code(), "reason": "Audit me"},
        format="json",
    )
    entry = (
        AdminAuditEntry.objects.filter(
            action="kill_switch.toggle", entity_id=str(flag.pk)
        )
        .order_by("-id")
        .first()
    )
    assert entry is not None
    assert entry.before_json == {"enabled": True}
    assert entry.after_json == {"enabled": False}
    assert entry.reason == "Audit me"


def test_toggle_busts_public_flags_cache() -> None:
    flag = _seed_switch("warnings_feature", enabled=True)
    cache.set(PUBLIC_FLAGS_CACHE_KEY, {flag.key: True}, 60)
    _client(_super_with_mfa()).post(
        f"{KILL_URL}/{flag.key}/toggle",
        {"mfa_code": _valid_code(), "reason": "Bust the cache"},
        format="json",
    )
    assert cache.get(PUBLIC_FLAGS_CACHE_KEY) is None


def test_toggle_propagates_to_config_public() -> None:
    flag = _seed_switch("warnings_feature", enabled=True)
    anon = APIClient()
    assert anon.get(CONFIG_PUBLIC_URL).json()["flags"][flag.key] is True
    _client(_super_with_mfa()).post(
        f"{KILL_URL}/{flag.key}/toggle",
        {"mfa_code": _valid_code(), "reason": "Kill it"},
        format="json",
    )
    assert anon.get(CONFIG_PUBLIC_URL).json()["flags"][flag.key] is False


# --- Unknown key -------------------------------------------------------------


def test_unknown_switch_key_404() -> None:
    resp = _client(_super_with_mfa()).post(
        f"{KILL_URL}/not_a_switch/toggle",
        {"mfa_code": _valid_code(), "reason": "x"},
        format="json",
    )
    assert resp.status_code == 404, resp.content


# --- Auth / role gate --------------------------------------------------------


def test_rejects_anonymous() -> None:
    assert APIClient().get(KILL_URL).status_code in (401, 403)


def test_super_only_list() -> None:
    _seed_switch("warnings_feature")
    super_admin = _super_with_mfa()
    assert _client(super_admin).get(KILL_URL).status_code == 200


@pytest.mark.parametrize(
    "role",
    [AdminRole.OPS, AdminRole.FINANCE, AdminRole.COMPLIANCE, AdminRole.SUPPORT],
)
def test_non_super_roles_denied(role: str) -> None:
    flag = _seed_switch("warnings_feature", enabled=True)
    admin = AdminUserFactory(role=role, totp_secret_enc=encrypt(TOTP_SECRET))
    client = _client(admin)
    assert client.get(KILL_URL).status_code == 403
    resp = client.post(
        f"{KILL_URL}/{flag.key}/toggle",
        {"mfa_code": _valid_code(), "reason": "should be denied"},
        format="json",
    )
    assert resp.status_code == 403
    flag.refresh_from_db()
    assert flag.enabled is True  # unchanged
