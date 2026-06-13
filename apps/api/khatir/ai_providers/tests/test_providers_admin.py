"""Tests for the admin AI-provider endpoints (EPIC-14.T-009 §12).

Covers: list, create (API key encrypted at rest, never returned), the non-BD
OCR DPA gate (rejected without a reference, allowed with one, and BD-domain OCR
or non-OCR categories exempt), PATCH edit + audit, test-connection (gateway
mocked), aggregated usage, and the super/ops role gate.

Admin auth here is the dedicated admin JWT realm, exactly as in the pricing and
user-management admin tests.
"""

from __future__ import annotations

from decimal import Decimal
from unittest import mock

import pytest
from rest_framework.test import APIClient

from khatir.admin_portal.auth_tokens import issue_access_token
from khatir.admin_portal.models import AdminAuditEntry
from khatir.admin_portal.tests.factories import AdminUserFactory
from khatir.ai_providers.client import AIGatewayError, AIGatewayResult
from khatir.ai_providers.enums import AICategory
from khatir.ai_providers.models import AIProvider
from khatir.ai_providers.tests.factories import AIProviderFactory, AIUsageLogFactory
from khatir.core.encryption import decrypt
from khatir.core.enums import AdminRole

pytestmark = pytest.mark.django_db

PROVIDERS_URL = "/admin/api/ai-providers"
USAGE_URL = "/admin/api/ai-usage"


def _auth_client(role: str = AdminRole.OPS) -> APIClient:
    admin = AdminUserFactory(role=role)
    token, _ = issue_access_token(admin.pk, admin.role)
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    return client


# --- List -------------------------------------------------------------------


def test_list_returns_all_providers() -> None:
    AIProviderFactory(provider_key="alpha")
    AIProviderFactory(provider_key="beta", active=False)
    body = _auth_client().get(PROVIDERS_URL).json()
    keys = {row["provider_key"] for row in body}
    assert {"alpha", "beta"} <= keys
    # Ciphertext is never exposed; only a boolean flag.
    assert "api_key_enc" not in body[0]
    assert "api_key" not in body[0]
    assert "has_api_key" in body[0]


# --- Create -----------------------------------------------------------------


def test_create_provider() -> None:
    resp = _auth_client().post(
        PROVIDERS_URL,
        {
            "category": AICategory.CHAT,
            "provider_key": "openai",
            "model_name": "gpt-4o",
            "api_key": "sk-live-secret",
            "active": True,
        },
        format="json",
    )
    assert resp.status_code == 201
    body = resp.json()
    assert body["provider_key"] == "openai"
    assert body["has_api_key"] is True
    # Plaintext key never returned.
    assert "api_key" not in body
    # Stored encrypted; decrypt round-trips to the plaintext.
    provider = AIProvider.objects.get(pk=body["id"])
    assert provider.api_key_enc != "sk-live-secret"
    assert decrypt(provider.api_key_enc) == "sk-live-secret"


def test_create_writes_audit() -> None:
    resp = _auth_client().post(
        PROVIDERS_URL,
        {"category": AICategory.CHAT, "provider_key": "anthropic"},
        format="json",
    )
    entry = AdminAuditEntry.objects.filter(
        action="ai_provider.create", entity_id=str(resp.json()["id"])
    ).first()
    assert entry is not None


# --- DPA gate ---------------------------------------------------------------


def test_dpa_required_for_ocr() -> None:
    """A non-BD OCR provider (default/foreign endpoint) needs a dpa_reference."""
    resp = _auth_client().post(
        PROVIDERS_URL,
        {
            "category": AICategory.OCR,
            "provider_key": "google_vision",
            "endpoint_url": "https://vision.googleapis.com",
        },
        format="json",
    )
    assert resp.status_code == 400
    assert "dpa_reference" in resp.json()["error"]["details"]


def test_dpa_satisfied_for_ocr_with_reference() -> None:
    resp = _auth_client().post(
        PROVIDERS_URL,
        {
            "category": AICategory.OCR,
            "provider_key": "google_vision",
            "endpoint_url": "https://vision.googleapis.com",
            "dpa_reference": "DPA-2026-001",
        },
        format="json",
    )
    assert resp.status_code == 201


def test_dpa_not_required_for_bd_ocr() -> None:
    resp = _auth_client().post(
        PROVIDERS_URL,
        {
            "category": AICategory.OCR,
            "provider_key": "local_ocr",
            "endpoint_url": "https://ocr.khatir.com.bd",
        },
        format="json",
    )
    assert resp.status_code == 201


def test_dpa_not_required_for_non_ocr() -> None:
    resp = _auth_client().post(
        PROVIDERS_URL,
        {"category": AICategory.CHAT, "provider_key": "openai"},
        format="json",
    )
    assert resp.status_code == 201


def test_dpa_enforced_on_patch_switch_to_ocr() -> None:
    provider = AIProviderFactory(
        category=AICategory.CHAT, endpoint_url="https://api.openai.com"
    )
    resp = _auth_client().patch(
        f"{PROVIDERS_URL}/{provider.pk}",
        {"category": AICategory.OCR},
        format="json",
    )
    assert resp.status_code == 400
    assert "dpa_reference" in resp.json()["error"]["details"]


# --- Edit (PATCH) -----------------------------------------------------------


def test_patch_applies_changes_and_audits() -> None:
    provider = AIProviderFactory(provider_key="p1", active=True)
    resp = _auth_client().patch(
        f"{PROVIDERS_URL}/{provider.pk}",
        {"active": False, "model_name": "v2"},
        format="json",
    )
    assert resp.status_code == 200
    provider.refresh_from_db()
    assert provider.active is False
    assert provider.model_name == "v2"
    entry = AdminAuditEntry.objects.filter(
        action="ai_provider.update", entity_id=str(provider.pk)
    ).first()
    assert entry is not None
    assert entry.before_json["active"] is True
    assert entry.after_json["active"] is False


def test_patch_rotates_api_key() -> None:
    provider = AIProviderFactory()
    _auth_client().patch(
        f"{PROVIDERS_URL}/{provider.pk}",
        {"api_key": "sk-rotated"},
        format="json",
    )
    provider.refresh_from_db()
    assert decrypt(provider.api_key_enc) == "sk-rotated"


def test_patch_unknown_provider_404() -> None:
    resp = _auth_client().patch(
        f"{PROVIDERS_URL}/999999", {"active": False}, format="json"
    )
    assert resp.status_code == 404


# --- test-connection --------------------------------------------------------


def test_connection_ok() -> None:
    provider = AIProviderFactory(provider_key="openai", model_name="gpt-4o")
    with mock.patch(
        "khatir.ai_providers.admin_views.call_gateway",
        return_value=AIGatewayResult(
            data={"ok": True}, provider_key="openai", model_name="gpt-4o"
        ),
    ) as gw:
        resp = _auth_client().post(
            f"{PROVIDERS_URL}/{provider.pk}/test-connection", format="json"
        )
    assert resp.status_code == 200
    body = resp.json()
    assert body["ok"] is True
    assert body["provider_key"] == "openai"
    gw.assert_called_once()


def test_connection_failure_reports_not_ok() -> None:
    provider = AIProviderFactory()
    with mock.patch(
        "khatir.ai_providers.admin_views.call_gateway",
        side_effect=AIGatewayError("bad creds", status_code=401),
    ):
        resp = _auth_client().post(
            f"{PROVIDERS_URL}/{provider.pk}/test-connection", format="json"
        )
    assert resp.status_code == 200
    body = resp.json()
    assert body["ok"] is False
    assert "bad creds" in body["detail"]


# --- Usage ------------------------------------------------------------------


def test_usage_aggregates_by_category() -> None:
    chat = AIProviderFactory(category=AICategory.CHAT)
    AIUsageLogFactory(
        provider=chat,
        category=AICategory.CHAT,
        tokens_used=100,
        cost_usd=Decimal("0.10"),
        success=True,
    )
    AIUsageLogFactory(
        provider=chat,
        category=AICategory.CHAT,
        tokens_used=50,
        cost_usd=Decimal("0.05"),
        success=False,
    )
    body = _auth_client().get(USAGE_URL).json()
    chat_row = next(r for r in body["by_category"] if r["category"] == "chat")
    assert chat_row["tokens_used"] == 150
    assert Decimal(chat_row["cost_usd"]) == Decimal("0.15")
    assert chat_row["call_count"] == 2
    assert chat_row["success_count"] == 1
    assert Decimal(body["totals"]["cost_usd"]) == Decimal("0.15")
    assert body["totals"]["tokens_used"] == 150


# --- Role gate --------------------------------------------------------------


def test_anonymous_denied() -> None:
    assert APIClient().get(PROVIDERS_URL).status_code in (401, 403)


@pytest.mark.parametrize("role", [AdminRole.SUPER, AdminRole.OPS])
def test_platform_roles_allowed(role: str) -> None:
    assert _auth_client(role).get(PROVIDERS_URL).status_code == 200


@pytest.mark.parametrize(
    "role", [AdminRole.FINANCE, AdminRole.COMPLIANCE, AdminRole.SUPPORT]
)
def test_other_roles_denied(role: str) -> None:
    assert _auth_client(role).get(PROVIDERS_URL).status_code == 403


def test_disabled_admin_denied() -> None:
    admin = AdminUserFactory(role=AdminRole.OPS, disabled=True)
    token, _ = issue_access_token(admin.pk, admin.role)
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    assert client.get(PROVIDERS_URL).status_code in (401, 403)
