"""User-management business logic for the admin portal — EPIC-12.T-003.

Operations staff search, inspect, and act on customer ``accounts.User`` rows.
Views validate input and serialize output; every decision, mutation, JWT
invalidation, and audit write happens here.

JWT invalidation on suspend (task §15)
--------------------------------------
The customer realm uses ``djangorestframework-simplejwt`` with the
``token_blacklist`` app enabled. Suspending a user flips ``is_active=False``
(simplejwt's ``JWTAuthentication`` rejects inactive users, so *access* tokens
stop working immediately) **and** blacklists every outstanding *refresh* token
for that user so a leaked refresh token can no longer mint fresh access tokens.
Both halves are needed: the first kills live access tokens, the second prevents
re-minting.
"""

from __future__ import annotations

from typing import Any

from django.db import transaction
from django.db.models import Q, QuerySet
from django.utils import timezone
from rest_framework_simplejwt.token_blacklist.models import (
    BlacklistedToken,
    OutstandingToken,
)

from khatir.accounts.models import User
from khatir.admin_portal.models import AdminAuditEntry, AdminUser
from khatir.billing.enums import SubscriptionStatus
from khatir.billing.models import PricingTier, Subscription
from khatir.core.exceptions import ConflictError, NotFoundError, ValidationError

from .audit import admin_audit

#: How many recent audit-trail rows to attach to a user detail payload.
AUDIT_TRAIL_LIMIT = 20


def search_users(query: str) -> QuerySet[User]:
    """Return a queryset of users matching ``query`` (newest first).

    Searches by phone (substring), name (case-insensitive substring), numeric
    ID (exact), and masked NID via the user's linked tenant profiles. An empty
    query returns every user.
    """
    qs = User.objects.all()
    term = (query or "").strip()
    if not term:
        return qs.order_by("-created_at")

    predicate = (
        Q(phone__icontains=term)
        | Q(name__icontains=term)
        | Q(tenant_profiles__nid_number_masked__icontains=term)
    )
    if term.isdigit():
        predicate |= Q(pk=int(term))

    return qs.filter(predicate).distinct().order_by("-created_at")


def get_user_or_404(user_id: int) -> User:
    """Load a customer user by id, raising :class:`NotFoundError` if missing."""
    try:
        return User.objects.get(pk=user_id)
    except User.DoesNotExist as exc:
        raise NotFoundError("User not found.") from exc


def _current_subscription(user: User) -> Subscription | None:
    """The user's most recent subscription, if any."""
    return (
        Subscription.objects.filter(user=user)
        .select_related("tier")
        .order_by("-created_at")
        .first()
    )


def _usage(user: User) -> dict[str, int]:
    """Lightweight platform-usage counters for the detail page."""
    return {
        "buildings": user.buildings.count(),
        "tenant_profiles": user.tenant_profiles.count(),
        "subscriptions": Subscription.objects.filter(user=user).count(),
    }


def recent_audit_trail(user: User) -> QuerySet[AdminAuditEntry]:
    """Recent admin-action audit rows targeting this user (newest first)."""
    return AdminAuditEntry.objects.filter(
        entity_type="accounts.user", entity_id=str(user.pk)
    ).order_by("-created_at")[:AUDIT_TRAIL_LIMIT]


def user_detail(user: User) -> dict[str, Any]:
    """Assemble the full admin detail payload (profile + sub + usage + audit).

    The serialization of each sub-object happens in the view; this returns the
    raw model instances / counters so the view stays declarative.
    """
    return {
        "user": user,
        "subscription": _current_subscription(user),
        "usage": _usage(user),
        "audit_trail": recent_audit_trail(user),
    }


def _blacklist_all_refresh_tokens(user: User) -> int:
    """Blacklist every outstanding refresh token for ``user``; return the count.

    Idempotent: tokens already blacklisted are skipped via ``get_or_create``.
    """
    outstanding = OutstandingToken.objects.filter(user=user)
    count = 0
    for token in outstanding:
        _, created = BlacklistedToken.objects.get_or_create(token=token)
        if created:
            count += 1
    return count


@transaction.atomic
def suspend_user(
    *,
    user: User,
    admin_user: AdminUser,
    reason: str,
    ip: str | None = None,
) -> User:
    """Deactivate ``user`` + invalidate all their JWTs, audited.

    ``reason`` is mandatory (enforced by the serializer). Setting
    ``is_active=False`` makes simplejwt reject the user's access tokens
    immediately; blacklisting their refresh tokens prevents re-minting.
    """
    if not reason.strip():
        raise ValidationError("A suspension reason is required.")
    if not user.is_active:
        raise ConflictError("User is already suspended.")

    user.is_active = False
    user.save(update_fields=["is_active", "updated_at"])
    blacklisted = _blacklist_all_refresh_tokens(user)

    admin_audit(
        admin_user=admin_user,
        action="user.suspend",
        entity=user,
        before={"is_active": True},
        after={"is_active": False, "refresh_tokens_blacklisted": blacklisted},
        ip=ip,
        reason=reason,
    )
    return user


@transaction.atomic
def reactivate_user(
    *,
    user: User,
    admin_user: AdminUser,
    reason: str = "",
    ip: str | None = None,
) -> User:
    """Re-enable a previously suspended user, audited."""
    if user.is_active:
        raise ConflictError("User is already active.")

    user.is_active = True
    user.save(update_fields=["is_active", "updated_at"])

    admin_audit(
        admin_user=admin_user,
        action="user.reactivate",
        entity=user,
        before={"is_active": False},
        after={"is_active": True},
        ip=ip,
        reason=reason,
    )
    return user


@transaction.atomic
def upgrade_subscription(
    *,
    user: User,
    admin_user: AdminUser,
    tier_id: int,
    reason: str,
    billing_cycle: str = "",
    ip: str | None = None,
) -> Subscription:
    """Manually move ``user`` onto ``tier_id`` (operations override), audited.

    Updates the user's most recent subscription in place, or creates an active
    one if they have none. ``reason`` is mandatory.
    """
    if not reason.strip():
        raise ValidationError("A reason is required.")

    try:
        tier = PricingTier.objects.get(pk=tier_id)
    except PricingTier.DoesNotExist as exc:
        raise NotFoundError("Pricing tier not found.") from exc

    subscription = _current_subscription(user)
    if subscription is None:
        now = timezone.now()
        before: dict[str, Any] = {"tier": None}
        subscription = Subscription.objects.create(
            user=user,
            tier=tier,
            billing_cycle=billing_cycle or "monthly",
            status=SubscriptionStatus.ACTIVE,
            start_at=now,
            next_billing_at=now,
        )
    else:
        before = {
            "tier_id": subscription.tier_id,
            "billing_cycle": subscription.billing_cycle,
        }
        subscription.tier = tier
        if billing_cycle:
            subscription.billing_cycle = billing_cycle
        subscription.save(update_fields=["tier", "billing_cycle", "updated_at"])

    admin_audit(
        admin_user=admin_user,
        action="user.upgrade_subscription",
        entity=user,
        before=before,
        after={"tier_id": tier.pk, "billing_cycle": subscription.billing_cycle},
        ip=ip,
        reason=reason,
    )
    return subscription
