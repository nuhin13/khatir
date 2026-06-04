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

from django.db import transaction

from khatir.accounts.models import User
from khatir.core.audit import audit
from khatir.core.enums import Role
from khatir.core.exceptions import NotFoundError
from khatir.leases.enums import RentScheduleStatus
from khatir.leases.models import Lease, RentSchedule

from .messaging import send_rent_link
from .models import RentRequest
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
