"""Admin-portal refund queue endpoints — EPIC-12.T-004.

Finance staff review the **pending payment intents** recorded by the EPIC-10
subscribe stub and either approve a refund (records it as processed and cancels
the subscription) or deny it with a reason.

There is no dedicated ``PaymentIntent`` table for the MVP: EPIC-10.T-004 records
each paid-tier subscribe as a customer-realm :class:`~khatir.core.models.AuditEntry`
with ``action="subscription.payment_intent"`` and ``after={"state": "pending", …}``
(see ``billing/services.py`` ``# STUB:`` marker). The refund queue is therefore the
set of those entries that have **not yet** been resolved.

Resolving an intent appends a follow-up ``subscription.payment_intent`` entry on
the same subscription with ``after.state`` of ``"refunded"`` or ``"refund_denied"``
and a ``resolves`` back-reference to the original intent's id. An intent is
"pending" only while no later entry on the same subscription resolves it, so the
queue is naturally append-only (no audit row is ever mutated) and idempotent.

Authz is the dedicated admin JWT realm (``AdminJWTAuthentication`` →
``request.admin_user``) gated on the ``billing`` section: only ``finance`` and
``super`` may view or act. Every approve/deny also writes an immutable
:class:`~khatir.admin_portal.models.AdminAuditEntry` (the staff-action trail).

Real MFS (bKash/Nagad) refund-API integration is a later task (§15); here a
processed refund only records the decision and updates the subscription state.
"""

from __future__ import annotations

from typing import Any, cast

from django.db import transaction
from rest_framework import serializers
from rest_framework.permissions import BasePermission
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from khatir.billing.enums import SubscriptionStatus
from khatir.billing.models import Subscription
from khatir.core.audit import audit
from khatir.core.exceptions import ConflictError, NotFoundError, ValidationError
from khatir.core.models import AuditEntry
from khatir.core.responses import success

from .audit import admin_audit
from .authentication import AdminJWTAuthentication, IsAdminAuthenticated
from .models import AdminUser
from .permissions import SECTION_ROLES, AdminSection

#: The customer-realm audit action under which the EPIC-10 stub records intents.
PAYMENT_INTENT_ACTION = "subscription.payment_intent"

#: ``after.state`` values that mean an intent is awaiting a finance decision.
_PENDING_STATE = "pending"
#: Terminal states an approve / deny writes.
_REFUNDED_STATE = "refunded"
_DENIED_STATE = "refund_denied"

#: Roles allowed in the billing section (super is always included).
_BILLING_ROLES = SECTION_ROLES[AdminSection.BILLING]


def _client_ip(request: Request) -> str | None:
    return request.META.get("REMOTE_ADDR")


class IsBillingAdmin(BasePermission):
    """Allow only a non-disabled admin in the billing section (finance/super)."""

    def has_permission(self, request: Request, view: APIView) -> bool:
        admin_user = getattr(request, "admin_user", None)
        if not isinstance(admin_user, AdminUser) or admin_user.disabled:
            return False
        return admin_user.role in _BILLING_ROLES


# --- queue resolution -------------------------------------------------------


def _resolved_intent_ids() -> set[int]:
    """Ids of payment intents already approved or denied.

    A resolution entry carries ``after.resolves = <original intent id>``; any
    intent whose id appears there is no longer pending.
    """
    resolved: set[int] = set()
    rows = AuditEntry.objects.filter(action=PAYMENT_INTENT_ACTION).values_list(
        "after", flat=True
    )
    for after in rows:
        if isinstance(after, dict):
            ref = after.get("resolves")
            if isinstance(ref, int):
                resolved.add(ref)
    return resolved


def pending_refunds() -> list[dict[str, Any]]:
    """Return the queue of unresolved pending payment intents (newest first)."""
    resolved = _resolved_intent_ids()
    intents = (
        AuditEntry.objects.filter(action=PAYMENT_INTENT_ACTION)
        .select_related("actor")
        .order_by("-created_at")
    )
    queue: list[dict[str, Any]] = []
    for intent in intents:
        after = intent.after if isinstance(intent.after, dict) else {}
        if after.get("state") != _PENDING_STATE:
            continue
        if intent.pk in resolved:
            continue
        queue.append(_serialize_intent(intent, after))
    return queue


def _serialize_intent(intent: AuditEntry, after: dict[str, Any]) -> dict[str, Any]:
    """Shape one pending intent for the queue list."""
    return {
        "id": intent.pk,
        "subscription_id": int(intent.target_id) if intent.target_id else None,
        "user_id": intent.actor_id,
        "tier_key": after.get("tier_key"),
        "billing_cycle": after.get("billing_cycle"),
        "provider": after.get("provider"),
        "state": after.get("state"),
        "created_at": intent.created_at.isoformat(),
    }


def _get_pending_intent(intent_id: int) -> AuditEntry:
    """Load a *pending, unresolved* payment intent or raise the right error.

    A missing/non-intent id is a 404; an intent that is already resolved (or was
    never in a pending state) is a 409 conflict.
    """
    try:
        intent = AuditEntry.objects.get(pk=intent_id, action=PAYMENT_INTENT_ACTION)
    except AuditEntry.DoesNotExist as exc:
        raise NotFoundError("Refund request not found.") from exc

    after = intent.after if isinstance(intent.after, dict) else {}
    if after.get("state") != _PENDING_STATE:
        raise ConflictError("This payment intent is not pending a refund decision.")
    if intent.pk in _resolved_intent_ids():
        raise ConflictError("This refund request has already been processed.")
    return intent


@transaction.atomic
def process_refund(
    *,
    intent: AuditEntry,
    admin_user: AdminUser,
    approve: bool,
    reason: str,
    ip: str | None = None,
) -> dict[str, Any]:
    """Approve or deny the refund for ``intent``; record + audit the decision.

    Approving writes a ``refunded`` resolution intent and cancels the linked
    subscription; denying writes a ``refund_denied`` resolution and leaves the
    subscription untouched. ``reason`` is mandatory for a denial. Both paths
    append a customer-realm resolution :class:`AuditEntry` and an immutable
    admin-action :class:`AdminAuditEntry`.
    """
    if not approve and not reason.strip():
        raise ValidationError("A reason is required to deny a refund.")

    before_after = intent.after if isinstance(intent.after, dict) else {}
    subscription = _intent_subscription(intent)

    new_state = _REFUNDED_STATE if approve else _DENIED_STATE
    resolution_after: dict[str, Any] = {
        "resolves": intent.pk,
        "tier_key": before_after.get("tier_key"),
        "billing_cycle": before_after.get("billing_cycle"),
        "provider": before_after.get("provider"),
        "state": new_state,
        "reason": reason,
    }
    audit(
        actor=subscription.user if subscription is not None else None,
        action=PAYMENT_INTENT_ACTION,
        target=subscription,
        before={"state": _PENDING_STATE},
        after=resolution_after,
    )

    sub_before: dict[str, Any] | None = None
    sub_after: dict[str, Any] | None = None
    if approve and subscription is not None and subscription.status != (
        SubscriptionStatus.CANCELLED
    ):
        sub_before = {"status": subscription.status}
        subscription.status = SubscriptionStatus.CANCELLED
        subscription.save(update_fields=["status", "updated_at"])
        sub_after = {"status": subscription.status}

    admin_audit(
        admin_user=admin_user,
        action="refund.process",
        entity=subscription if subscription is not None else intent,
        before={"intent_id": intent.pk, "decision": _PENDING_STATE, **(
            {"subscription_status": sub_before["status"]} if sub_before else {}
        )},
        after={
            "decision": "approved" if approve else "denied",
            "state": new_state,
            **({"subscription_status": sub_after["status"]} if sub_after else {}),
        },
        ip=ip,
        reason=reason,
    )

    return {
        "intent_id": intent.pk,
        "decision": "approved" if approve else "denied",
        "state": new_state,
        "subscription_id": subscription.pk if subscription is not None else None,
        "subscription_status": (
            subscription.status if subscription is not None else None
        ),
    }


def _intent_subscription(intent: AuditEntry) -> Subscription | None:
    """Resolve the :class:`Subscription` an intent targets, locked for update."""
    if intent.target_type != "billing.subscription" or not intent.target_id:
        return None
    return (
        Subscription.objects.select_for_update()
        .select_related("user", "tier")
        .filter(pk=int(intent.target_id))
        .first()
    )


# --- serializers ------------------------------------------------------------


class RefundProcessSerializer(serializers.Serializer[dict[str, Any]]):
    """Body for ``POST .../{id}/process``.

    ``approve`` decides the outcome; ``reason`` is mandatory on a denial (also
    re-checked in the service so it can never be bypassed).
    """

    approve = serializers.BooleanField()
    reason = serializers.CharField(
        max_length=255, required=False, allow_blank=True, default=""
    )

    def validate(self, attrs: dict[str, Any]) -> dict[str, Any]:
        if not attrs["approve"] and not attrs.get("reason", "").strip():
            raise serializers.ValidationError(
                {"reason": "A reason is required to deny a refund."}
            )
        return attrs


# --- views ------------------------------------------------------------------


class RefundQueueView(APIView):
    """``GET /admin/api/billing/refunds`` — pending refund requests (finance/super)."""

    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsAdminAuthenticated, IsBillingAdmin]

    def get(self, request: Request) -> Response:
        return success({"results": pending_refunds()})


class RefundProcessView(APIView):
    """``POST /admin/api/billing/refunds/{id}/process`` — approve or deny."""

    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsAdminAuthenticated, IsBillingAdmin]

    def post(self, request: Request, intent_id: int) -> Response:
        serializer = RefundProcessSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        intent = _get_pending_intent(intent_id)
        result = process_refund(
            intent=intent,
            admin_user=cast(AdminUser, request.admin_user),  # type: ignore[attr-defined]
            approve=serializer.validated_data["approve"],
            reason=serializer.validated_data.get("reason", ""),
            ip=_client_ip(request),
        )
        return success(result)
