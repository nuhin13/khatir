"""Pricing-tier business logic for the admin portal — EPIC-12.T-001.

Finance staff edit a :class:`PricingTier`'s values and want to see the impact —
how many subscribers are affected and the estimated monthly-revenue delta —
*before* committing. The preview is a pure, read-only calculation; the edit is
a transactional, audited, cache-busting write.

Views validate input and serialize output; every decision, mutation, audit
write, and cache invalidation happens here.

Impact model (task §2)
----------------------
"Subscribers affected" = the count of *active* subscriptions currently on the
tier. "Revenue delta" = the change in monthly recurring revenue across those
subscribers, computed per subscriber against the price for *their* billing cycle
(an annual subscriber's annual price is amortised to a monthly figure). A
``None`` price is treated as ৳0 (the free tier).
"""

from __future__ import annotations

from decimal import Decimal
from typing import Any

from django.db import transaction
from django.db.models import QuerySet

from khatir.admin_portal.models import AdminUser
from khatir.billing.enums import BillingCycle, SubscriptionStatus
from khatir.billing.models import PricingTier, Subscription
from khatir.billing.public_config import invalidate_public_config_cache
from khatir.core.exceptions import NotFoundError, ValidationError

from .audit import admin_audit
from .pricing_serializers import EDITABLE_TIER_FIELDS

#: Months per year — used to amortise an annual price to a monthly figure.
_MONTHS_PER_YEAR = Decimal(12)


def list_tiers() -> QuerySet[PricingTier]:
    """Return every pricing tier in plan-picker order (active and inactive)."""
    return PricingTier.objects.all().order_by("sort_order")


def get_tier_or_404(key: str) -> PricingTier:
    """Load a pricing tier by its stable ``key``, 404 if missing."""
    try:
        return PricingTier.objects.get(key=key)
    except PricingTier.DoesNotExist as exc:
        raise NotFoundError("Pricing tier not found.") from exc


def _monthly_equivalent(tier_like: Any, billing_cycle: str) -> Decimal:
    """The monthly-recurring price a subscriber on ``billing_cycle`` pays.

    ``tier_like`` exposes ``monthly_price`` / ``annual_price`` (a model instance
    or a dict of proposed values). A ``None`` price means free (৳0); an annual
    price is divided by 12 to compare like-for-like with monthly subscribers.
    """
    if billing_cycle == BillingCycle.ANNUAL:
        annual = _as_decimal(_field(tier_like, "annual_price"))
        return annual / _MONTHS_PER_YEAR
    return _as_decimal(_field(tier_like, "monthly_price"))


def _field(tier_like: Any, name: str) -> Any:
    if isinstance(tier_like, dict):
        return tier_like.get(name)
    return getattr(tier_like, name)


def _as_decimal(value: Any) -> Decimal:
    """Coerce a nullable price to a ``Decimal`` (``None`` → ৳0)."""
    if value is None:
        return Decimal("0")
    return value if isinstance(value, Decimal) else Decimal(str(value))


def _proposed_values(tier: PricingTier, changes: dict[str, Any]) -> dict[str, Any]:
    """The tier's price fields after applying ``changes`` (for preview math)."""
    return {
        "monthly_price": changes.get("monthly_price", tier.monthly_price),
        "annual_price": changes.get("annual_price", tier.annual_price),
    }


def compute_impact(tier: PricingTier, changes: dict[str, Any]) -> dict[str, Any]:
    """Read-only impact of applying ``changes`` to ``tier``.

    Returns the number of active subscribers on the tier and the estimated
    change in monthly recurring revenue (negative = revenue drop). Only price
    fields affect revenue; non-price changes yield a zero delta.
    """
    proposed = _proposed_values(tier, changes)
    subscriptions = Subscription.objects.filter(
        tier=tier, status=SubscriptionStatus.ACTIVE
    ).only("billing_cycle")

    affected = 0
    delta = Decimal("0")
    for sub in subscriptions:
        affected += 1
        old_monthly = _monthly_equivalent(tier, sub.billing_cycle)
        new_monthly = _monthly_equivalent(proposed, sub.billing_cycle)
        delta += new_monthly - old_monthly

    return {
        "subscribers_affected": affected,
        "monthly_revenue_delta": str(delta.quantize(Decimal("0.01"))),
    }


@transaction.atomic
def edit_tier(
    *,
    key: str,
    admin_user: AdminUser,
    changes: dict[str, Any],
    reason: str,
    ip: str | None = None,
) -> PricingTier:
    """Apply ``changes`` to the tier identified by ``key``, audited.

    Locks the row (``select_for_update``) for the duration of the transaction,
    records a before/after field diff in the admin audit log, and busts the
    ``/config/public`` cache so the public catalogue reflects the change. A
    non-blank ``reason`` is mandatory.
    """
    if not reason.strip():
        raise ValidationError("A reason is required.")
    if not changes:
        raise ValidationError("No changes supplied.")

    tier = _locked_tier_or_404(key)

    before = {field: _serialize(getattr(tier, field)) for field in changes}
    for field, value in changes.items():
        setattr(tier, field, value)
    tier.save(update_fields=[*changes.keys(), "updated_at"])
    after = {field: _serialize(getattr(tier, field)) for field in changes}

    admin_audit(
        admin_user=admin_user,
        action="pricing.tier.edit",
        entity=tier,
        before=before,
        after=after,
        ip=ip,
        reason=reason,
    )
    invalidate_public_config_cache()
    return tier


def _locked_tier_or_404(key: str) -> PricingTier:
    try:
        return PricingTier.objects.select_for_update().get(key=key)
    except PricingTier.DoesNotExist as exc:
        raise NotFoundError("Pricing tier not found.") from exc


def _serialize(value: Any) -> Any:
    """JSON-safe representation of a field value for the audit diff."""
    if isinstance(value, Decimal):
        return str(value)
    return value


# Re-export so views can reference the canonical editable-field set.
__all__ = [
    "EDITABLE_TIER_FIELDS",
    "compute_impact",
    "edit_tier",
    "get_tier_or_404",
    "list_tiers",
]
