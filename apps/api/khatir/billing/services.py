"""Billing service layer — metering + free-limit enforcement (EPIC-10 T-003).

``check_tenant_limit(user)`` is the single guard the tenants domain calls before
creating a tenant. It compares the landlord/manager's current active tenant count
against their plan's allowance and raises :class:`TierLimitExceeded` (error code
``tier_limit_exceeded``) when adding one more would exceed it.

The allowance comes from the user's **active** subscription tier
(``PricingTier.tenant_max``; ``None`` = unlimited). With no active subscription the
landlord is on the free tier, so the limit is the admin-editable
``free_tier_tenant_limit`` ``SystemConfig`` key (default 2) — never hardcoded.

Counting reuses ``Tenant.objects.for_user`` (the single source of tenant
visibility truth, EPIC-04 T-008 §15) so the metered count never drifts from what
the user can actually see and soft-deleted tenants are excluded.

The check takes a ``select_for_update`` lock so two concurrent creates for the
same landlord cannot both slip past the limit (EPIC-10 T-003 §2): each waits its
turn, re-counts, and the second one is correctly blocked.
"""

from __future__ import annotations

from datetime import timedelta
from typing import Any

from django.db import transaction
from django.utils import timezone

from khatir.accounts.models import User
from khatir.core.audit import audit
from khatir.core.config import get_config
from khatir.core.exceptions import (
    TierFeatureGated,
    TierLimitExceeded,
    ValidationError,
)

from .enums import BillingCycle, SubscriptionStatus
from .models import PricingTier, Subscription

FREE_TIER_LIMIT_KEY = "free_tier_tenant_limit"
_DEFAULT_FREE_LIMIT = 2


def _tenant_limit(user: Any) -> int | None:
    """Resolve the tenant allowance for ``user``.

    Returns the ``tenant_max`` of the user's active-subscription tier, ``None``
    when that tier is unlimited, or the ``free_tier_tenant_limit`` config when the
    user has no active subscription. The subscription rows are locked
    (``select_for_update``) so a concurrent create for the same user serializes
    behind this read.
    """
    subscription = (
        Subscription.objects.select_for_update()
        .filter(user=user, status=SubscriptionStatus.ACTIVE)
        .select_related("tier")
        .order_by("-created_at")
        .first()
    )
    if subscription is not None:
        # ``tenant_max = None`` on the tier means unlimited.
        return subscription.tier.tenant_max

    return int(get_config(FREE_TIER_LIMIT_KEY, _DEFAULT_FREE_LIMIT))


def check_tenant_limit(user: Any) -> None:
    """Raise :class:`TierLimitExceeded` if ``user`` cannot add another tenant.

    Counts the active (non-deleted) tenants visible to ``user`` and compares to
    the plan allowance. A ``None`` allowance is unlimited and always passes. Must
    be called inside the tenant-create transaction so the ``select_for_update``
    lock is held across the count → compare → insert window, closing the race
    where two simultaneous creates both read "at limit minus one".
    """
    # Local import avoids a tenants ↔ billing import cycle at module load.
    from khatir.tenants.models import Tenant

    with transaction.atomic():
        limit = _tenant_limit(user)
        if limit is None:
            return

        current = Tenant.objects.for_user(user).count()
        if current >= limit:
            raise TierLimitExceeded(
                details={"limit": limit, "tenants_used": current},
            )


def check_can_verify(user: Any) -> None:
    """Raise :class:`TierFeatureGated` if ``user``'s plan excludes NID verification.

    NID OCR/voice extraction and verification (EPIC-04 T-005/T-006, EPIC-17) are a
    paid-tier feature (EPIC-10 T-009 §2). Verification is allowed only when the
    user holds an **active** subscription whose tier has
    ``includes_verification == True``. A free-tier user (no active subscription)
    or a paid tier that does not bundle verification is blocked with the
    ``feature_requires_upgrade`` envelope (402), which the client routes to the
    upgrade prompt. Free-tier users can still add tenants by manual entry — only
    the OCR/voice/verification path is gated, never tenant creation itself.
    """
    subscription = (
        Subscription.objects.filter(user=user, status=SubscriptionStatus.ACTIVE)
        .select_related("tier")
        .order_by("-created_at")
        .first()
    )
    if subscription is not None and subscription.tier.includes_verification:
        return

    raise TierFeatureGated(details={"feature": "nid_verification"})


# --- subscribe / upgrade (EPIC-10 T-004) -------------------------------------
#
# Views stay thin (validate → call a service → serialize). ``subscribe``
# resolves the requested :class:`PricingTier` by key, rejecting an unknown or
# inactive one, then creates or upgrades the caller's single subscription in one
# atomic write and audits it. The acting user is the service argument (the view
# passes ``request.user``), never the client body.
#
# Payment is STUBBED for the MVP: a paid tier records a ``payment_intent`` audit
# marker (``pending``) instead of charging an MFS gateway — an admin confirms it
# manually. The real MFS integration is a separate task/epic; the ``# STUB:``
# marker below is the exact wiring point (§15).

# Approximate cycle lengths for the next-billing stamp. Exact day-of-month
# proration is an MFS-integration concern (§15), not MVP scope.
_CYCLE_DAYS = {
    BillingCycle.MONTHLY: 30,
    BillingCycle.ANNUAL: 365,
}


def _subscription_snapshot(subscription: Subscription) -> dict[str, Any]:
    """A JSON-safe audit snapshot of a subscription's billing state."""
    return {
        "tier_key": subscription.tier.key,
        "billing_cycle": subscription.billing_cycle,
        "status": subscription.status,
        "start_at": subscription.start_at.isoformat(),
        "next_billing_at": subscription.next_billing_at.isoformat(),
    }


def _resolve_active_tier(tier_key: str) -> PricingTier:
    """Return the active :class:`PricingTier` for ``tier_key`` or reject it.

    An unknown key or an inactive (no longer offered) tier is a 400
    ``validation_error`` — a client may never subscribe to a tier that is not
    currently on offer.
    """
    try:
        tier = PricingTier.objects.get(key=tier_key)
    except PricingTier.DoesNotExist:
        raise ValidationError(
            "Unknown pricing tier.", details={"tier_key": tier_key}
        ) from None
    if not tier.active:
        raise ValidationError(
            "This pricing tier is no longer available.",
            details={"tier_key": tier_key},
        )
    return tier


def _is_paid(tier: PricingTier) -> bool:
    """True if the tier carries any non-zero price (needs payment)."""
    return bool(tier.monthly_price) or bool(tier.annual_price)


def subscribe(
    *,
    actor: User,
    tier_key: str,
    billing_cycle: str = BillingCycle.MONTHLY,
) -> Subscription:
    """Create or upgrade ``actor``'s subscription to ``tier_key`` (T-004 §2).

    The caller holds at most one subscription row: if one exists it is upgraded
    in place (tier / cycle / dates refreshed, status reset to ``active``),
    otherwise a new one is created. The whole write is atomic and locks the
    caller's existing rows (``select_for_update``) so concurrent subscribes
    serialize. Audited as ``subscription.create`` or ``subscription.upgrade``
    (no payment data). Payment is stubbed — see the ``# STUB:`` marker.
    """
    tier = _resolve_active_tier(tier_key)
    now = timezone.now()
    next_billing_at = now + timedelta(days=_CYCLE_DAYS[BillingCycle(billing_cycle)])

    with transaction.atomic():
        existing = (
            Subscription.objects.select_for_update()
            .filter(user=actor)
            .select_related("tier")
            .order_by("-created_at")
            .first()
        )
        before = _subscription_snapshot(existing) if existing else None
        action = "subscription.upgrade" if existing else "subscription.create"

        if existing is not None:
            subscription = existing
            subscription.tier = tier
            subscription.billing_cycle = billing_cycle
            subscription.status = SubscriptionStatus.ACTIVE
            subscription.next_billing_at = next_billing_at
        else:
            subscription = Subscription(
                user=actor,
                tier=tier,
                billing_cycle=billing_cycle,
                status=SubscriptionStatus.ACTIVE,
                start_at=now,
                next_billing_at=next_billing_at,
            )
        subscription.save()

    audit(
        actor=actor,
        action=action,
        target=subscription,
        before=before,
        after=_subscription_snapshot(subscription),
    )

    # STUB: real MFS (bKash/Nagad) payment integration goes here. For the MVP a
    # paid tier only records a pending payment-intent marker — an admin confirms
    # the charge manually. Replace this block with a gateway call (and gate the
    # status on its result) when the MFS epic lands (§15).
    if _is_paid(tier):
        audit(
            actor=actor,
            action="subscription.payment_intent",
            target=subscription,
            before=None,
            after={
                "tier_key": tier.key,
                "billing_cycle": billing_cycle,
                "provider": "mfs",
                "state": "pending",
            },
        )

    return subscription


def current_subscription(user: User) -> Subscription | None:
    """Return ``user``'s most recent subscription, or ``None`` (free tier)."""
    return (
        Subscription.objects.filter(user=user)
        .select_related("tier")
        .order_by("-created_at")
        .first()
    )


def tenant_limit_for(subscription: Subscription) -> int | None:
    """The tenant cap implied by a subscription's tier (``None`` = unlimited)."""
    return subscription.tier.tenant_max
