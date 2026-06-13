"""factory-boy factories for the history-sharing domain.

factory-boy ships no type stubs, so its dynamic attributes are opaque to mypy;
the per-module override in ``pyproject.toml`` relaxes the untyped-call checks.
"""

from __future__ import annotations

import factory

from khatir.accounts.tests.factories import UserFactory
from khatir.compliance.tests.factories import ConsentRecordFactory
from khatir.historyshare.models import HistoryShare
from khatir.tenants.tests.factories import TenantFactory


class HistoryShareFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = HistoryShare

    tenant = factory.SubFactory(TenantFactory)  # type: ignore[attr-defined]
    recipient_landlord = factory.SubFactory(UserFactory)  # type: ignore[attr-defined]
    consent_record = factory.SubFactory(ConsentRecordFactory)  # type: ignore[attr-defined]
    scope: dict[str, object] = {}
    factual_stats: dict[str, object] = {}
