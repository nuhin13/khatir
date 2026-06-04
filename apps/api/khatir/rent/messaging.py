"""Deliver the rent-request web link to a tenant (T-004 slice).

T-008 (reminder cadence) re-uses the same send path it uses for the first send,
so the delivery logic lives here in one place. It reuses the EPIC-01
:func:`~khatir.messaging.factory.send_with_fallback` (WhatsApp → SMS, console in
dev) rather than building a new sender. EPIC-15 will template these messages;
keep the copy in one place (``_render_message``).
"""

from __future__ import annotations

from django.conf import settings
from django.db.models.functions import Now
from django.utils import timezone

from khatir.core.exceptions import ValidationError
from khatir.messaging.factory import send_with_fallback

from .models import RentRequest


def _public_link(token: str) -> str:
    """Build the public ``/r/{token}`` URL from the configured web base URL."""
    base = getattr(settings, "PUBLIC_WEB_BASE_URL", "") or "https://khatir.app"
    return f"{base.rstrip('/')}/r/{token}"


def _render_message(rent_request: RentRequest, link: str) -> str:
    """Render the bilingual (Bangla + English) rent-link message body."""
    amount = f"{rent_request.amount:.0f}"
    return (
        f"আপনার {rent_request.period} মাসের ভাড়া ৳{amount} পরিশোধ করুন: {link}\n"
        f"Pay your rent of ৳{amount} for {rent_request.period}: {link}"
    )


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
    :func:`send_with_fallback`, then stamps ``sent_via``/``sent_at``. When
    ``is_reminder`` is set the reminder counters are bumped too so the cadence
    task can enforce its window and max-reminder cap. Returns the saved request.
    """
    link = _public_link(rent_request.link_token)
    recipient = _resolve_recipient(rent_request)
    channel = send_with_fallback(recipient, _render_message(rent_request, link))

    rent_request.sent_via = channel.value
    update_fields = ["sent_via", "updated_at"]
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
