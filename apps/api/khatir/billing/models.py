"""Billing domain models — Domain 7 of ``06_database_schema.md``.

``PricingTier`` holds the available plans (admin-editable; never hardcoded).
``Subscription`` ties a landlord ``User`` to a ``PricingTier`` with billing
dates and a lifecycle status.

Neither model is user-facing in the sense of being soft-deleted — the tier
catalogue is admin-controlled and subscriptions follow a formal lifecycle
(active → past_due → cancelled) rather than a soft-delete pattern.
"""

from __future__ import annotations

from django.conf import settings
from django.db import models

from khatir.core.models import TimeStampedModel

from .enums import BillingCycle, SubscriptionStatus


class PricingTier(TimeStampedModel):
    """An available subscription plan — editable from the admin portal.

    ``key`` is a stable code used in code logic (e.g. ``free``, ``bundle_20``).
    ``tenant_max = None`` means unlimited.
    ``monthly_price / annual_price = None`` means ৳0 (free tier).
    """

    key = models.CharField(
        max_length=64,
        unique=True,
        help_text="Stable code: free / per_tenant / bundle_20 / …",
    )
    label = models.CharField(max_length=120, help_text="Display name (English).")
    label_bn = models.CharField(max_length=120, help_text="Display name (Bangla).")
    tenant_min = models.IntegerField(
        default=0,
        help_text="Minimum tenant count this tier covers.",
    )
    tenant_max = models.IntegerField(
        null=True,
        blank=True,
        default=None,
        help_text="Maximum tenant count; null = unlimited.",
    )
    monthly_price = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        null=True,
        blank=True,
        default=None,
        help_text="Monthly price in Taka; null = free.",
    )
    annual_price = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        null=True,
        blank=True,
        default=None,
        help_text="Annual price in Taka; null = free.",
    )
    includes_verification = models.BooleanField(
        default=False,
        help_text="Does this tier allow NID verification?",
    )
    included_credits = models.IntegerField(
        default=0,
        help_text="Bundled NID verification credits.",
    )
    active = models.BooleanField(
        default=True,
        help_text="Is this tier currently offered?",
    )
    sort_order = models.IntegerField(
        default=0,
        help_text="Display order in plan picker (ascending).",
    )

    class Meta:
        ordering = ("sort_order",)

    def __str__(self) -> str:
        return f"{self.label} ({self.key})"


class Subscription(TimeStampedModel):
    """A landlord's current plan and billing state.

    ``user`` and ``tier`` use PROTECT so a subscription row is never silently
    orphaned when the user or tier is removed — explicit cancellation first.
    """

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="subscriptions",
        help_text="The subscribing landlord.",
    )
    tier = models.ForeignKey(
        PricingTier,
        on_delete=models.PROTECT,
        related_name="subscriptions",
        help_text="The plan they are on.",
    )
    billing_cycle = models.CharField(
        max_length=8,
        choices=BillingCycle.choices,
        default=BillingCycle.MONTHLY,
        help_text="monthly / annual.",
    )
    status = models.CharField(
        max_length=16,
        choices=SubscriptionStatus.choices,
        default=SubscriptionStatus.ACTIVE,
        help_text="active / past_due / cancelled.",
    )
    start_at = models.DateTimeField(
        help_text="When this subscription started (UTC).",
    )
    next_billing_at = models.DateTimeField(
        help_text="When the next billing event is due (UTC).",
    )

    class Meta:
        ordering = ("-created_at",)
        indexes = [models.Index(fields=["user", "status"])]

    def __str__(self) -> str:
        return f"{self.user} — {self.tier} ({self.billing_cycle})"
