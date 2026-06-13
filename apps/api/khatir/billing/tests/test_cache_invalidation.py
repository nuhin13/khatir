"""PricingTier write busts the ``/config/public`` cache (EPIC-12 T-002 §12).

The public-config tier catalogue is memoised under
:data:`~khatir.billing.public_config.PUBLIC_CONFIG_CACHE_KEY`. A ``post_save`` /
``post_delete`` signal on :class:`PricingTier` must drop that key on *any* tier
mutation so clients see the change within the 60s TTL — regardless of whether
the write came through the admin edit service, the Django admin, or elsewhere.

Covers:
* a tier save deletes a pre-populated cache key;
* a tier delete deletes the key too;
* after the bust, ``/config/public`` reflects the new tier values.
"""

from __future__ import annotations

from decimal import Decimal

import pytest
from django.core.cache import cache
from rest_framework.test import APIClient

from khatir.billing.models import PricingTier
from khatir.billing.public_config import PUBLIC_CONFIG_CACHE_KEY

pytestmark = pytest.mark.django_db

CONFIG_PUBLIC = "/api/v1/config/public"


def _prime_cache() -> None:
    """Stuff a sentinel under the public-config key to detect invalidation."""
    cache.set(PUBLIC_CONFIG_CACHE_KEY, ["stale"], 60)
    assert cache.get(PUBLIC_CONFIG_CACHE_KEY) == ["stale"]


def test_cache_busted_on_tier_change() -> None:
    """Saving a tier drops the shared public-config cache key."""
    _prime_cache()

    tier = PricingTier.objects.get(key="bundle_20")
    tier.monthly_price = tier.monthly_price + 1 if tier.monthly_price else 1
    tier.save(update_fields=["monthly_price", "updated_at"])

    assert cache.get(PUBLIC_CONFIG_CACHE_KEY) is None


def test_cache_busted_on_tier_create() -> None:
    """Creating a tier also drops the cache key."""
    _prime_cache()

    PricingTier.objects.create(
        key="t002_temp",
        label="Temp",
        label_bn="Temp",
        tenant_min=1,
        tenant_max=1,
        sort_order=99,
        active=False,
    )

    assert cache.get(PUBLIC_CONFIG_CACHE_KEY) is None


def test_cache_busted_on_tier_delete() -> None:
    """Deleting a tier drops the cache key."""
    tier = PricingTier.objects.create(
        key="t002_to_delete",
        label="Doomed",
        label_bn="Doomed",
        tenant_min=1,
        tenant_max=1,
        sort_order=98,
        active=False,
    )
    _prime_cache()

    tier.delete()

    assert cache.get(PUBLIC_CONFIG_CACHE_KEY) is None


def test_config_public_reflects_tier_change_after_bust() -> None:
    """After a price edit, ``/config/public`` returns the new value."""
    _prime_cache()

    tier = PricingTier.objects.get(key="bundle_20")
    new_price = (tier.monthly_price or Decimal("0")) + Decimal("100")
    tier.monthly_price = new_price
    tier.save(update_fields=["monthly_price", "updated_at"])

    # Signal already cleared the key; nothing stale should linger.
    assert cache.get(PUBLIC_CONFIG_CACHE_KEY) is None

    response = APIClient().get(CONFIG_PUBLIC)
    assert response.status_code == 200
    tiers = {t["key"]: t for t in response.json()["pricing"]["tiers"]}
    assert Decimal(tiers["bundle_20"]["monthly_price"]) == new_price
