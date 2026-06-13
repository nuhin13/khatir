"""Deliver the rent-request web link to a tenant (T-004 slice).

T-008 (reminder cadence) re-uses the same send path it uses for the first send,
so the delivery logic lives here in one place. It reuses the EPIC-01
:func:`~khatir.messaging.factory.send_with_fallback` (WhatsApp → SMS, console in
dev) rather than building a new sender. EPIC-15.T-006 retrofits the copy onto
the admin-editable ``rent_reminder_due`` :class:`NotificationTemplate`: the body
text now comes from :func:`~khatir.notifications.models.get_template` rather than
a hard-coded string, so back-office staff can edit the rent-link wording without
a deploy. The delivery behaviour (bilingual Bangla + English body carrying the
public ``/r/{token}`` link, WhatsApp → SMS fallback) is unchanged.
"""

from __future__ import annotations

from django.conf import settings
from django.db.models.functions import Now
from django.utils import timezone

from khatir.core.exceptions import ValidationError
from khatir.messaging.factory import send_with_fallback
from khatir.notifications.models import get_template

from .enums import RentRequestStatus
from .models import RentRequest

#: Stable key of the admin-editable template that backs the rent-link message.
_RENT_REMINDER_TEMPLATE_KEY = "rent_reminder_due"


def _public_link(token: str) -> str:
    """Build the public ``/r/{token}`` URL from the configured web base URL."""
    base = getattr(settings, "PUBLIC_WEB_BASE_URL", "") or "https://khatir.app"
    return f"{base.rstrip('/')}/r/{token}"


def _template_variables(rent_request: RentRequest, link: str) -> dict[str, str]:
    """Build the ``rent_reminder_due`` template variables for this request.

    Mirrors the placeholder names declared on the seeded template
    (``tenant_name``, ``amount``, ``property_name``, ``due_date``,
    ``payment_link``). Amount is the whole-Taka string the prior hard-coded copy
    used; ``due_date`` is the rent ``period`` (YYYY-MM).
    """
    lease = rent_request.lease
    return {
        "tenant_name": lease.tenant.name,
        "amount": f"৳{rent_request.amount:.0f}",
        "property_name": lease.unit.building.name,
        "due_date": rent_request.period,
        "payment_link": link,
    }


def _render_message(rent_request: RentRequest, link: str) -> str:
    """Render the bilingual (Bangla + English) rent-link message body.

    The copy is sourced from the admin-editable ``rent_reminder_due``
    :class:`NotificationTemplate` (EPIC-15.T-006). Both language bodies are
    rendered with the request's variables and joined Bangla-first, preserving
    the prior single bilingual-string delivery contract.
    """
    rendered = get_template(_RENT_REMINDER_TEMPLATE_KEY).render(
        _template_variables(rent_request, link)
    )
    return f"{rendered['body_bn']}\n{rendered['body_en']}"


def _resolve_recipient(rent_request: RentRequest) -> str:
    """Return the tenant's phone number for delivery.

    Reads the linked app-user phone on the lease's tenant. Raises
    :class:`~khatir.core.exceptions.ValidationError` if no contact is known so
    callers (and the reminder task) can skip/flag the request rather than
    silently dropping it.
    """
    tenant = rent_request.lease.tenant
    user = tenant.linked_user
    phone = getattr(user, "phone", "") if user else ""
    if not phone:
        raise ValidationError(
            f"RentRequest #{rent_request.pk} has no tenant contact to message."
        )
    return phone


def send_rent_link(rent_request: RentRequest, *, is_reminder: bool = False) -> RentRequest:
    """Send (or re-send) the rent link to the tenant and record the delivery.

    Builds the ``/r/{token}`` URL and a bilingual message, delivers it via
    :func:`send_with_fallback`, then stamps ``status``/``sent_via``/``sent_at``.
    On a successful first send the request moves to ``sent`` (the model default,
    re-affirmed here so a manual re-send recovers a request left un-sent). When
    ``is_reminder`` is set the reminder counters are bumped too so the cadence
    task can enforce its window and max-reminder cap. A failure to deliver
    propagates out of :func:`send_with_fallback` (it re-raises the last channel
    error), leaving the request untouched. Returns the saved request.
    """
    link = _public_link(rent_request.link_token)
    recipient = _resolve_recipient(rent_request)
    channel = send_with_fallback(recipient, _render_message(rent_request, link))

    rent_request.sent_via = channel.value
    update_fields = ["sent_via", "updated_at"]
    if rent_request.status != RentRequestStatus.SENT:
        rent_request.status = RentRequestStatus.SENT
        update_fields.append("status")
    if rent_request.sent_at is None:
        rent_request.sent_at = timezone.now()
        update_fields.append("sent_at")
    if is_reminder:
        rent_request.reminder_count += 1
        rent_request.last_reminded_at = Now()  # type: ignore[assignment]
        update_fields += ["reminder_count", "last_reminded_at"]

    rent_request.save(update_fields=update_fields)
    rent_request.refresh_from_db()
    return rent_request
