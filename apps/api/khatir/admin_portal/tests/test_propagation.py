"""End-to-end pricing-change propagation test (EPIC-12.T-010 §12).

The <60s guarantee test: a tier price edited through the *admin API* must be
reflected by ``/config/public`` once the cache-bust signal fires. This exercises
the full chain end to end — admin JWT auth + role gate (T-001) → PATCH edit
service (write, audit, cache bust) → ``post_save`` invalidation signal (T-002) →
the live ``/config/public`` selector returning the new value.

Unlike the unit tests (which mock the bust or save the model directly), this
test drives the real admin HTTP endpoint and then reads the real public endpoint,
so it catches regressions anywhere along that chain — a broken role gate, a
dropped cache bust, or a stale selector.
"""

from __future__ import annotations

from decimal import Decimal

import pytest
from django.core.cache import cache
from rest_framework.test import APIClient

from khatir.admin_portal.auth_tokens import issue_access_token
from khatir.admin_portal.tests.factories import AdminUserFactory
from khatir.billing.models import PricingTier
from khatir.billing.public_config import PUBLIC_CONFIG_CACHE_KEY
from khatir.core.enums import AdminRole

pytestmark = pytest.mark.django_db

TIERS_URL = "/admin/api/pricing/tiers"
CONFIG_PUBLIC = "/api/v1/config/public"


def _admin_client(role: str = AdminRole.FINANCE) -> APIClient:
    """An ``APIClient`` carrying a valid admin JWT for the pricing section."""
    admin = AdminUserFactory(role=role)
    token, _ = issue_access_token(admin.pk, admin.role)
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    return client


def _config_public_price(key: str) -> Decimal:
    """Read a tier's ``monthly_price`` straight from ``/config/public``."""
    response = APIClient().get(CONFIG_PUBLIC)
    assert response.status_code == 200
    tiers = {t["key"]: t for t in response.json()["pricing"]["tiers"]}
    return Decimal(tiers[key]["monthly_price"])


def test_tier_change_propagates_to_config_public() -> None:
    """Editing a tier via the admin API surfaces in ``/config/public``.

    Full chain: prime the public-config cache → PATCH the price through the
    admin endpoint → the edit service busts the key and the ``post_save``
    signal reinforces the bust → ``/config/public`` returns the new value.
    """
    # An active, publicly-listed tier with a known starting price.
    tier = PricingTier.objects.get(key="bundle_20")
    old_price = tier.monthly_price or Decimal("0")
    new_price = old_price + Decimal("123.00")

    # Prime the cache key with a sentinel; the edit must drop it. (``/config/public``
    # is computed live today, so the sentinel is a bust probe, not a stale source.)
    cache.set(PUBLIC_CONFIG_CACHE_KEY, ["stale"], 60)
    assert _config_public_price("bundle_20") == old_price

    resp = _admin_client().patch(
        f"{TIERS_URL}/{tier.key}",
        {"monthly_price": str(new_price), "reason": "Annual repricing"},
        format="json",
    )
    assert resp.status_code == 200

    # The write busted the shared cache key (explicit service call + signal).
    assert cache.get(PUBLIC_CONFIG_CACHE_KEY) is None

    # The public catalogue now reflects the admin-side edit within the window.
    assert _config_public_price("bundle_20") == new_price
