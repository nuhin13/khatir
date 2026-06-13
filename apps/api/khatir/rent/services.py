"""Rent-request service layer — business logic for create (T-003 §2).

Views stay thin (validate → call a service → serialize). A rent request is
created either from a scheduled month or as a manual one-off; in both cases the
landlord is derived from the lease (never trusted from the client), a
single-purpose signed ``link_token`` is minted (T-002), and the change is
audited via ``core.audit.audit`` (``domain.verb`` action strings).

Creating from a schedule also marks that ``RentSchedule`` row **requested**
(``RentScheduleStatus.REQUESTED``) so the same month is not re-asked. The actual
send (status → ``sent`` over a channel) happens in T-004; the request is created
already in ``sent`` status per the model default, ready for T-004 to dispatch.

All lease/schedule lookups are **scoped to the actor**: a lease or schedule the
actor cannot see resolves to a 404-style ``NotFoundError`` — we never reveal that
another user's lease exists.
"""

from __future__ import annotations

from decimal import Decimal
from typing import Any, cast

from django.conf import settings
from django.db import transaction
from django.utils import timezone

from khatir.accounts.models import User
from khatir.core import storage
from khatir.core.audit import audit
from khatir.core.enums import Role
from khatir.core.exceptions import ConflictError, NotFoundError
from khatir.leases.enums import RentScheduleStatus
from khatir.leases.models import Lease, RentSchedule
from khatir.messaging.factory import send_with_fallback

from .enums import RentRequestStatus
from .messaging import send_rent_link
from .models import Payment, PaymentProof, RentRequest
from .receipts import render_receipt_pdf
from .tokens import make_token


def _visible_landlord_ids(actor: User) -> list[Any]:
    """Landlord ids whose leases ``actor`` may act on (mirrors the queryset scope)."""
    role = getattr(actor, "role", None)
    if role == Role.LANDLORD:
        return [actor.pk]
    if role == Role.MANAGER:
        helper = getattr(actor, "managed_owner_ids", None)
        return list(helper()) if callable(helper) else []
    return []


def _scoped_lease(actor: User, lease_id: Any) -> Lease:
    """Return a lease ``actor`` may use, or raise ``NotFoundError``."""
    try:
        lease = cast(
            Lease,
            Lease.objects.get(  # type: ignore[misc]
                pk=lease_id, landlord_id__in=_visible_landlord_ids(actor)
            ),
        )
    except Lease.DoesNotExist as exc:
        raise NotFoundError("Lease not found.") from exc
    return lease


def _scoped_schedule(actor: User, schedule_id: Any) -> RentSchedule:
    """Return a schedule row on a lease ``actor`` may use, or raise ``NotFoundError``."""
    try:
        schedule = RentSchedule.objects.select_related("lease").get(  # type: ignore[misc]
            pk=schedule_id,
            lease__landlord_id__in=_visible_landlord_ids(actor),
        )
    except RentSchedule.DoesNotExist as exc:
        raise NotFoundError("Rent schedule not found.") from exc
    return schedule


def _snapshot(req: RentRequest) -> dict[str, Any]:
    """A JSON-safe snapshot of the created request for the audit row."""
    return {
        "lease_id": str(req.lease_id),
        "rent_schedule_id": str(req.rent_schedule_id) if req.rent_schedule_id else None,
        "amount": str(req.amount),
        "period": req.period,
        "sent_via": req.sent_via,
        "sent_at": req.sent_at.isoformat() if req.sent_at else None,
        "status": req.status,
    }


def create_rent_request(
    *,
    actor: User,
    rent_schedule: int | None = None,
    lease: int | None = None,
    amount: Decimal | None = None,
    period: str | None = None,
    sent_via: str | None = None,
    **_ignored: Any,
) -> RentRequest:
    """Create a rent request (from a schedule period or manual one-off).

    From a schedule: the lease, amount and period are taken from the schedule row
    and the row is marked ``requested``. Manual: the lease is used directly with
    the supplied amount/period and no schedule is linked. In both cases the
    landlord is derived from the lease, a signed ``link_token`` is minted, and a
    ``rent.request.create`` audit row is written. The whole operation is atomic.
    """
    with transaction.atomic():
        schedule_row: RentSchedule | None = None
        if rent_schedule is not None:
            schedule_row = _scoped_schedule(actor, rent_schedule)
            lease_obj = schedule_row.lease
            req_amount = schedule_row.amount
            req_period = schedule_row.period
        else:
            lease_obj = _scoped_lease(actor, lease)
            assert amount is not None and period is not None  # guaranteed by serializer
            req_amount = amount
            req_period = period

        request = RentRequest.objects.create(
            lease=lease_obj,
            rent_schedule=schedule_row,
            amount=req_amount,
            period=req_period,
            sent_via=sent_via or RentRequest._meta.get_field("sent_via").default,
        )

        # Single-purpose signed token (T-002) → persisted on the request.
        make_token(request)

        # Mark the source schedule month as requested so it is not re-asked.
        if schedule_row is not None and schedule_row.status != RentScheduleStatus.REQUESTED:
            schedule_row.status = RentScheduleStatus.REQUESTED
            schedule_row.save(update_fields=["status", "updated_at"])

    audit(
        actor=actor,
        action="rent.request.create",
        target=request,
        before=None,
        after=_snapshot(request),
    )
    return request


def send_rent_request(*, actor: User, request: RentRequest) -> RentRequest:
    """Deliver (or re-deliver) the rent link for ``request`` and audit it.

    Thin wrapper over the EPIC-01-backed :func:`send_rent_link` delivery so the
    view stays a validate→service→serialize shell. The before/after snapshot
    captures the ``status``/``sent_via``/``sent_at`` change for the audit trail;
    a delivery failure propagates (no partial save, no audit row).
    """
    before = _snapshot(request)
    send_rent_link(request)
    audit(
        actor=actor,
        action="rent.request.send",
        target=request,
        before=before,
        after=_snapshot(request),
    )
    return request


# ── proof submit: the one PaymentProof pipeline (T-006 web + EPIC-19 in-app) ────


def submit_payment_proof(
    *,
    rent_request: RentRequest,
    proof_type: str,
    value: str = "",
    photo_ref: str = "",
) -> PaymentProof:
    """Record a tenant's payment proof against ``rent_request`` and advance it.

    The single source of truth for the proof step, shared by the public web-link
    page (EPIC-07 T-006) and the in-app endpoint (EPIC-19 T-003) so neither
    duplicates the create + status transition. Creates the :class:`PaymentProof`
    (``submitted_at`` stamped now) and, only when the request is still ``sent``,
    advances it to ``proof_submitted`` — a re-submission against an already
    verified/rejected request never regresses its status.
    """
    proof = PaymentProof.objects.create(
        rent_request=rent_request,
        type=proof_type,
        value=value,
        photo_ref=photo_ref,
        submitted_at=timezone.now(),
    )
    if rent_request.status == RentRequestStatus.SENT:
        rent_request.status = RentRequestStatus.PROOF_SUBMITTED
        rent_request.save(update_fields=["status", "updated_at"])
    return proof


# ── settle: verify / mark-received / reject (T-007) ─────────────────────────────

# A request can only be settled (verified / received / rejected) from an open
# state; settling an already-settled request is a 409 (not a silent no-op) so a
# double-verify never mints a second Payment + receipt.
_OPEN_STATUSES = frozenset(
    {RentRequestStatus.SENT, RentRequestStatus.PROOF_SUBMITTED}
)


def _receipt_link(rent_request: RentRequest) -> str:
    """Build the public ``/r/{token}/receipt`` URL for the settled request."""
    base = getattr(settings, "PUBLIC_WEB_BASE_URL", "") or "https://khatir.app"
    return f"{base.rstrip('/')}/r/{rent_request.link_token}/receipt"


def _notify_tenant_receipt(rent_request: RentRequest) -> None:
    """Notify the tenant their payment was confirmed, linking the web receipt.

    Reuses the EPIC-01 :func:`send_with_fallback` (WhatsApp → SMS, console in
    dev). A missing tenant contact is non-fatal here — verification already
    succeeded and the receipt is viewable at the existing link — so a delivery
    failure is swallowed rather than rolling back the confirmed payment.
    """
    tenant = rent_request.lease.tenant
    user = getattr(tenant, "linked_user", None)
    phone = getattr(user, "phone", "") if user else ""
    if not phone:
        return
    link = _receipt_link(rent_request)
    amount = f"{rent_request.amount:.0f}"
    message = (
        f"আপনার {rent_request.period} মাসের ভাড়া ৳{amount} নিশ্চিত হয়েছে। "
        f"রসিদ: {link}\n"
        f"Your rent of ৳{amount} for {rent_request.period} is confirmed. "
        f"Receipt: {link}"
    )
    try:
        send_with_fallback(phone, message)
    except Exception:  # noqa: BLE001 — receipt delivery is best-effort, never fatal
        pass


def _mark_schedule_paid(rent_request: RentRequest) -> None:
    """Mark the source ``RentSchedule`` month paid, if one is linked."""
    schedule = rent_request.rent_schedule
    if schedule is not None and schedule.status != RentScheduleStatus.PAID:
        schedule.status = RentScheduleStatus.PAID
        schedule.save(update_fields=["status", "updated_at"])


def _settle_payment(*, actor: User, rent_request: RentRequest, action: str) -> Payment:
    """Shared verify / mark-received path: Payment + receipt + schedule + notify.

    Creates the :class:`Payment` (``verified_by``/``verified_at``), renders and
    stores the receipt PDF (reusing the EPIC-05 renderer + EPIC-04 storage seam),
    moves the request to ``verified`` and the schedule to ``paid``, then audits
    under ``action``. Notification is sent after commit (best-effort). The DB
    work is atomic; a settled request cannot be re-settled (409).
    """
    if rent_request.status not in _OPEN_STATUSES:
        raise ConflictError(
            f"RentRequest #{rent_request.pk} is already {rent_request.status}."
        )

    before = _snapshot(rent_request)
    with transaction.atomic():
        now = timezone.now()
        payment = Payment.objects.create(
            rent_request=rent_request,
            verified_by=actor,
            verified_at=now,
        )
        receipt_bytes = render_receipt_pdf(rent_request, payment)
        payment.receipt_ref = storage.store_encrypted(receipt_bytes, kind="pdf")
        payment.save(update_fields=["receipt_ref", "updated_at"])

        rent_request.status = RentRequestStatus.VERIFIED
        rent_request.save(update_fields=["status", "updated_at"])
        _mark_schedule_paid(rent_request)

    audit(
        actor=actor,
        action=action,
        target=rent_request,
        before=before,
        after=_snapshot(rent_request),
    )
    _notify_tenant_receipt(rent_request)
    return payment


def verify_rent_request(*, actor: User, request: RentRequest) -> Payment:
    """Verify a submitted proof: create the Payment + receipt and settle.

    Confirms the tenant's submitted proof. See :func:`_settle_payment` for the
    shared mechanics; audited as ``rent.payment.verify``.
    """
    return _settle_payment(
        actor=actor, rent_request=request, action="rent.payment.verify"
    )


def mark_received(*, actor: User, request: RentRequest) -> Payment:
    """Record an off-platform (cash) payment with no proof and settle.

    Same outcome as :func:`verify_rent_request` — Payment, receipt PDF, schedule
    paid, tenant notified — for a landlord who collected cash directly. Audited
    as ``rent.payment.mark_received``.
    """
    return _settle_payment(
        actor=actor, rent_request=request, action="rent.payment.mark_received"
    )


def reject_rent_request(
    *, actor: User, request: RentRequest, reason: str
) -> RentRequest:
    """Reject a request (e.g. a bad/missing proof) with a reason; no Payment.

    Moves the request to ``rejected`` and audits the change under
    ``rent.payment.reject`` with the supplied ``reason`` captured in the audit
    ``after`` snapshot. A request that is already settled cannot be rejected
    (409). No receipt, no schedule change, no notification.
    """
    if request.status not in _OPEN_STATUSES:
        raise ConflictError(
            f"RentRequest #{request.pk} is already {request.status}."
        )

    before = _snapshot(request)
    request.status = RentRequestStatus.REJECTED
    request.save(update_fields=["status", "updated_at"])

    after = _snapshot(request)
    after["reject_reason"] = reason
    audit(
        actor=actor,
        action="rent.payment.reject",
        target=request,
        before=before,
        after=after,
    )
    return request
