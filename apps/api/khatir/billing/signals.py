"""Cache-invalidation signals for the billing app — EPIC-12.T-002.

``/config/public`` surfaces the active pricing-tier catalogue (EPIC-10 T-005),
memoised under :data:`~khatir.billing.public_config.PUBLIC_CONFIG_CACHE_KEY`
with a 60s max TTL. A tier write must therefore drop that key so every client
sees the new prices/limits within the TTL window.

The admin pricing-edit service (EPIC-12 T-001) already busts the key explicitly,
but a :class:`PricingTier` can also change through the Django admin, a data
migration, or a future code path. Hooking ``post_save`` / ``post_delete`` on the
model itself makes invalidation unconditional: *any* tier mutation, however it
happens, clears the shared key. Both writers target the same key, so the
explicit call and the signal are idempotent — a double delete is harmless.
"""

from __future__ import annotations

from typing import Any

from django.db.models.signals import post_delete, post_save
from django.dispatch import receiver

from .models import PricingTier
from .public_config import invalidate_public_config_cache


@receiver(post_save, sender=PricingTier)
@receiver(post_delete, sender=PricingTier)
def _bust_public_config_on_tier_write(
    sender: type, instance: PricingTier, **kwargs: Any
) -> None:
    """Drop the cached ``/config/public`` tier catalogue on any tier write."""
    invalidate_public_config_cache()
