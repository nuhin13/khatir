"""factory-boy factories for the ai_providers domain.

factory-boy ships no type stubs, so its dynamic attributes are opaque to mypy;
the per-module override in ``pyproject.toml`` relaxes the untyped-call checks.
"""

from __future__ import annotations

import factory

from khatir.ai_providers.enums import AICategory
from khatir.ai_providers.models import AIProvider, AIUsageLog
from khatir.core.encryption import encrypt


class AIProviderFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = AIProvider

    category = AICategory.CHAT
    provider_key = factory.Sequence(lambda n: f"vendor_{n}")  # type: ignore[attr-defined]
    is_primary = False
    is_fallback = False
    model_name = "test-model"
    api_key_enc = factory.LazyFunction(lambda: encrypt("sk-test-key"))  # type: ignore[attr-defined]
    endpoint_url = ""
    params_json = None
    dpa_reference = ""
    active = True


class AIUsageLogFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = AIUsageLog

    provider = factory.SubFactory(AIProviderFactory)  # type: ignore[attr-defined]
    category = AICategory.CHAT
    request_count = 1
    tokens_used = 100
    cost_usd = "0.01"
    success = True
    latency_ms = 250
    failover_from = None
