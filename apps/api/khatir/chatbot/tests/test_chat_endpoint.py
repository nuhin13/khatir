"""API tests for the chat endpoint (EPIC-23.T-002 §12).

Drives ``POST /api/v1/chat`` and ``GET /api/v1/chat/history`` through DRF's
``APIClient`` with the AI gateway's single seam (``call_gateway``) mocked, so no
real provider is reached. Covers: a message persists both turns and returns the
reply, conversations continue, the ``chatbot_enabled`` flag gate (on by default,
403 when off), scoping (a user can never read or extend another user's
conversation), validation, the per-user rate-limit, gateway-failure handling,
and that the user's own context reaches the system prompt.
"""

from __future__ import annotations

from typing import Any
from unittest import mock

import pytest
from django.conf import settings
from django.core.cache import cache
from django.test import override_settings
from rest_framework import status
from rest_framework.test import APIClient

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.ai_providers.client import AIGatewayError, AIGatewayResult
from khatir.chatbot.enums import ChatRole
from khatir.chatbot.models import ChatConversation, ChatMessage
from khatir.featureflags.enums import FlagScope
from khatir.featureflags.tests.factories import FeatureFlagFactory

pytestmark = pytest.mark.django_db

CHAT_PATH = "/api/v1/chat"
HISTORY_PATH = "/api/v1/chat/history"
CALL_GATEWAY = "khatir.chatbot.services.call_gateway"

REPLY = AIGatewayResult(
    data={"reply": "You collected 12,000 BDT this month.", "role": "assistant"},
    provider_key="stub",
    model_name="stub-chat",
)


@pytest.fixture
def landlord() -> User:
    user: User = UserFactory(  # type: ignore[assignment]
        phone="+8801712345678", name="Rahim", role=Role.LANDLORD
    )
    return user


@pytest.fixture
def client(landlord: User) -> APIClient:
    api = APIClient()
    api.force_authenticate(user=landlord)
    return api


def _send(
    client: APIClient, content: str = "What's my collection?", **extra: object
) -> tuple[Any, mock.MagicMock]:
    body: dict[str, object] = {"content": content, **extra}
    with mock.patch(CALL_GATEWAY, return_value=REPLY) as patched:
        resp = client.post(CHAT_PATH, body, format="json")
    return resp, patched


# --- happy path --------------------------------------------------------------


def test_send_persists_both_turns_and_returns_reply(client: APIClient) -> None:
    resp, _ = _send(client)

    assert resp.status_code == status.HTTP_201_CREATED
    body = resp.json()
    assert body["role"] == "assistant"
    assert body["content"] == "You collected 12,000 BDT this month."
    assert body["conversation_id"]

    convo = ChatConversation.objects.get(pk=body["conversation_id"])
    roles = list(convo.messages.order_by("created_at").values_list("role", flat=True))
    assert roles == [ChatRole.USER, ChatRole.ASSISTANT]


def test_continue_existing_conversation(client: APIClient) -> None:
    first, _ = _send(client, "Hi")
    convo_id = first.json()["conversation_id"]

    second, patched = _send(client, "And next month?", conversation_id=convo_id)
    assert second.status_code == status.HTTP_201_CREATED
    assert second.json()["conversation_id"] == convo_id

    # No new conversation row was created on the follow-up turn.
    assert ChatConversation.objects.count() == 1
    # The gateway saw the prior turns replayed (system + multi-message history).
    sent_payload = patched.call_args.args[1]
    assert sent_payload["system"]
    assert len(sent_payload["messages"]) >= 3  # hi, reply, follow-up


def test_user_context_reaches_system_prompt(client: APIClient) -> None:
    _, patched = _send(client)
    system = patched.call_args.args[1]["system"]
    assert "Rahim" in system  # the caller's OWN name, scoped in


# --- flag gate ---------------------------------------------------------------


def test_flag_on_by_default(client: APIClient) -> None:
    resp, _ = _send(client)
    assert resp.status_code == status.HTTP_201_CREATED


def test_flag_off_returns_403(client: APIClient) -> None:
    FeatureFlagFactory(key="chatbot_enabled", scope=FlagScope.GLOBAL, enabled=False)

    resp, _ = _send(client)
    assert resp.status_code == status.HTTP_403_FORBIDDEN
    assert resp.json()["error"]["code"] == "feature_disabled"
    # Nothing was persisted when the kill-switch is off.
    assert ChatMessage.objects.count() == 0


# --- scoping -----------------------------------------------------------------


def test_cannot_extend_another_users_conversation(client: APIClient) -> None:
    other: User = UserFactory(phone="+8801799999999", role=Role.LANDLORD)  # type: ignore[assignment]
    foreign = ChatConversation.objects.create(user=other)

    resp, _ = _send(client, "leak?", conversation_id=foreign.pk)
    assert resp.status_code == status.HTTP_404_NOT_FOUND
    # The foreign conversation gained no messages.
    assert foreign.messages.count() == 0


def test_history_is_owner_scoped(client: APIClient, landlord: User) -> None:
    _send(client, "mine")

    other: User = UserFactory(phone="+8801788888888", role=Role.LANDLORD)  # type: ignore[assignment]
    other_convo = ChatConversation.objects.create(user=other)
    ChatMessage.objects.create(
        conversation=other_convo, role=ChatRole.USER, content="theirs"
    )

    resp = client.get(HISTORY_PATH)
    assert resp.status_code == status.HTTP_200_OK
    contents = [m["content"] for m in resp.json()["results"]]
    assert "mine" in contents
    assert "theirs" not in contents


# --- validation --------------------------------------------------------------


def test_blank_message_rejected(client: APIClient) -> None:
    resp, _ = _send(client, "   ")
    assert resp.status_code == status.HTTP_400_BAD_REQUEST


def test_unauthenticated_rejected() -> None:
    resp = APIClient().post(CHAT_PATH, {"content": "hi"}, format="json")
    assert resp.status_code in (
        status.HTTP_401_UNAUTHORIZED,
        status.HTTP_403_FORBIDDEN,
    )


def test_tenant_user_allowed(landlord: User) -> None:
    # Chat is for any authenticated user, not just landlords/managers.
    tenant: User = UserFactory(phone="+8801766666666", role=Role.TENANT)  # type: ignore[assignment]
    api = APIClient()
    api.force_authenticate(user=tenant)
    with mock.patch(CALL_GATEWAY, return_value=REPLY):
        resp = api.post(CHAT_PATH, {"content": "hi"}, format="json")
    assert resp.status_code == status.HTTP_201_CREATED


# --- gateway failure ---------------------------------------------------------


def test_gateway_failure_returns_502_but_keeps_user_turn(client: APIClient) -> None:
    with mock.patch(CALL_GATEWAY, side_effect=AIGatewayError("boom")):
        resp = client.post(CHAT_PATH, {"content": "hello"}, format="json")

    assert resp.status_code == status.HTTP_502_BAD_GATEWAY
    # The user turn is persisted (retry continues the thread); no assistant turn.
    assert ChatMessage.objects.filter(role=ChatRole.USER, content="hello").exists()
    assert not ChatMessage.objects.filter(role=ChatRole.ASSISTANT).exists()


# --- rate limit --------------------------------------------------------------


def _rest_with_rate(rate: str) -> dict[str, Any]:
    rest: dict[str, Any] = dict(settings.REST_FRAMEWORK)
    rest["DEFAULT_THROTTLE_RATES"] = {
        **rest["DEFAULT_THROTTLE_RATES"],
        "chat_message": rate,
    }
    return rest


@override_settings(REST_FRAMEWORK=_rest_with_rate("2/hour"))
def test_rate_limited(client: APIClient) -> None:
    cache.clear()
    assert _send(client)[0].status_code == status.HTTP_201_CREATED
    assert _send(client)[0].status_code == status.HTTP_201_CREATED

    resp, _ = _send(client)
    assert resp.status_code == status.HTTP_429_TOO_MANY_REQUESTS
    assert resp.json()["error"]["code"] == "rate_limited"
