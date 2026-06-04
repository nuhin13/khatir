"""Public-config selectors for ``/config/public`` (EPIC-10 T-005).

``/config/public`` surfaces the plan catalogue (all active tiers) plus, for an
authenticated caller, their current subscription/usage so the app can render
plan info and enforce limits client-side. Tiers serialize through the read-only
:class:`~khatir.billing.serializers.TierSerializer`; the subscription block is a
flat, non-sensitive dict — no prices, billing dates, or payment data (T-005 §14).

Tier *benefits* (``tenant_limit``, ``can_verify_nid``) derive from the caller's
**active** subscription tier only. A cancelled/past-due (or absent) subscription
falls back to the free tier: ``tenant_limit`` from the ``free_tier_tenant_limit``
``SystemConfig`` (never hardcoded) and ``can_verify_nid = False``. ``status`` still
reflects any most-recent row so the UI can show ``past_due`` / ``cancelled``.
"""

from __future__ import annotations

from typing import Any

from khatir.accounts.models import User

from .enums import SubscriptionStatus
from .models import PricingTier, Subscription
from .serializers import TierSerializer


def active_tiers() -> list[PricingTier]:
    """Return every active :class:`PricingTier` in plan-picker order."""
    return list(PricingTier.objects.filter(active=True).order_by("sort_order"))


def serialized_tiers() -> list[dict[str, Any]]:
    """The active tiers as plain dicts for the public-config envelope."""
    return list(TierSerializer(active_tiers(), many=True).data)


def _most_recent(user: User) -> Subscription | None:
    return (
        Subscription.objects.filter(user=user)
        .select_related("tier")
        .order_by("-created_at")
        .first()
    )


def _active(user: User) -> Subscription | None:
    return (
        Subscription.objects.filter(user=user, status=SubscriptionStatus.ACTIVE)
        .select_related("tier")
        .order_by("-created_at")
        .first()
    )


def subscription_block(user: User) -> dict[str, Any]:
    """Build the ``subscription`` block for an authenticated caller (T-005 §2).

    Reports the current plan key + status and tenant usage against the effective
    limit. Benefits come from the **active** subscription tier; with no active
    plan the caller is on the free tier (limit from config, no NID verification).
    """
    # Local import avoids a tenants <-> billing import cycle at module load.
    from khatir.tenants.usage import tenant_usage

    usage = tenant_usage(user)
    active = _active(user)
    current = _most_recent(user)

    if active is not None:
        tier_key: str = active.tier.key
        status: str = active.status
        tenant_limit: int | None = active.tier.tenant_max  # None = unlimited
        can_verify_nid: bool = active.tier.includes_verification
    else:
        tier_key = current.tier.key if current is not None else "free"
        status = current.status if current is not None else SubscriptionStatus.ACTIVE
        tenant_limit = usage.free_limit
        can_verify_nid = False

    return {
        "tier_key": tier_key,
        "status": status,
        "tenants_used": usage.tenants_used,
        "tenant_limit": tenant_limit,
        "can_verify_nid": can_verify_nid,
    }
