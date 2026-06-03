"""Billing-domain enums — Domain 7 of ``06_database_schema.md``.

Domain-specific (used only by ``PricingTier`` and ``Subscription``), so they
live in the owning app rather than ``khatir.core.enums``. Wire values are the
single source of truth in ``docs/architecture/enums.md`` — lowercase
snake_case strings, never integers.
"""

from django.db import models


class BillingCycle(models.TextChoices):
    """How often a subscription is billed."""

    MONTHLY = "monthly", "Monthly"
    ANNUAL = "annual", "Annual"


class SubscriptionStatus(models.TextChoices):
    """Current standing of a subscription."""

    ACTIVE = "active", "Active"
    PAST_DUE = "past_due", "Past due"
    CANCELLED = "cancelled", "Cancelled"
