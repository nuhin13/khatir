"""Tests for the chatbot guardrails + disclaimers (EPIC-23.T-004 §12).

T-004 hardens the system prompt: it must (a) instruct the model to refuse
out-of-scope requests, (b) refuse to give definitive legal/financial advice and
instead disclaim + suggest a qualified professional, and (c) stay bilingual
(Bangla/English). These assert the prompt that ships to the gateway carries
those rules and the disclaimer text. Keeping them on the prompt (one auditable
place) means every chat call inherits the guardrails.
"""

from __future__ import annotations

import pytest

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.chatbot.prompts import (
    BASE_SYSTEM_PROMPT,
    LEGAL_FINANCIAL_DISCLAIMER,
    build_system_prompt,
)

pytestmark = pytest.mark.django_db


@pytest.fixture
def landlord() -> User:
    user: User = UserFactory(  # type: ignore[assignment]
        phone="+8801712345678", name="Rahim", role=Role.LANDLORD
    )
    return user


# --- disclaimer presence -----------------------------------------------------


def test_base_prompt_carries_legal_financial_disclaimer() -> None:
    assert LEGAL_FINANCIAL_DISCLAIMER in BASE_SYSTEM_PROMPT


def test_disclaimer_is_bilingual() -> None:
    # English half references a professional; Bangla half references পেশাদার.
    assert "professional" in LEGAL_FINANCIAL_DISCLAIMER
    assert "পেশাদার" in LEGAL_FINANCIAL_DISCLAIMER


def test_prompt_refuses_definitive_legal_financial_advice() -> None:
    lowered = BASE_SYSTEM_PROMPT.lower()
    assert "legal" in lowered
    assert "financial" in lowered
    # Must recommend a professional rather than advising directly.
    assert "professional" in lowered


# --- scope refusal -----------------------------------------------------------


def test_prompt_instructs_refusal_of_out_of_scope() -> None:
    lowered = BASE_SYSTEM_PROMPT.lower()
    assert "out-of-scope" in lowered or "out of scope" in lowered
    assert "refuse" in lowered
    # Stays anchored to product/tenancy topics.
    assert "tenancy" in lowered


# --- bilingual ---------------------------------------------------------------


def test_prompt_is_bilingual() -> None:
    lowered = BASE_SYSTEM_PROMPT.lower()
    assert "bangla" in lowered
    assert "english" in lowered


# --- assembled prompt inherits guardrails ------------------------------------


def test_assembled_prompt_keeps_guardrails_and_user_scope(landlord: User) -> None:
    prompt = build_system_prompt(landlord)
    # Guardrails carried through into the full, context-bearing prompt.
    assert LEGAL_FINANCIAL_DISCLAIMER in prompt
    assert "refuse" in prompt.lower()
    # And the caller's OWN scoped data is still present, not stripped.
    assert "Rahim" in prompt
