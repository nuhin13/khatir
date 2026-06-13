"""factory-boy factories for the featureflags domain.

factory-boy ships no type stubs, so its dynamic attributes are opaque to mypy;
the per-module override in ``pyproject.toml`` relaxes the untyped-call checks.
"""

from __future__ import annotations

import factory

from khatir.featureflags.enums import FlagScope, KillSwitchAction
from khatir.featureflags.models import FeatureFlag, KillSwitchEvent


class FeatureFlagFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = FeatureFlag

    key = factory.Sequence(lambda n: f"flag_{n}")  # type: ignore[attr-defined]
    description = factory.Sequence(lambda n: f"Test flag {n}")  # type: ignore[attr-defined]
    scope = FlagScope.GLOBAL
    enabled = False
    value_json = None
    updated_by = None


class KillSwitchEventFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = KillSwitchEvent

    switch_key = factory.Sequence(lambda n: f"switch_{n}")  # type: ignore[attr-defined]
    action = KillSwitchAction.DISABLE
    reason = "Test kill-switch trigger."
    admin_user = None
    lawyer_reference = ""
