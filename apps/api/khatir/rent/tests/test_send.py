"""Tests for the rent-link send path (T-004).

``send_rent_link`` reuses the EPIC-01 ``send_with_fallback`` (WhatsApp → SMS,
console in dev). The unit tests patch that seam so they neither hit the network
nor depend on configured credentials; the fallback test instead forces a
non-dev environment and exercises the real selector (WhatsApp unconfigured →
falls back to SMS). The API tests drive ``POST /api/v1/rent-requests/{id}/send``
through DRF's ``APIClient`` with a real authenticated landlord.
"""

from __future__ import annotations

from unittest import mock

import pytest
from rest_framework import status
from rest_framework.test import APIClient

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.core.enums import Channel as CoreChannel
from khatir.core.exceptions import ValidationError
from khatir.core.models import AuditEntry
from khatir.leases.tests.factories import LeaseFactory
from khatir.rent.enums import RentRequestStatus
from khatir.rent.messaging import _public_link, _render_message, send_rent_link
from khatir.rent.models import RentRequest
from khatir.rent.tests.factories import RentRequestFactory

pytestmark = pytest.mark.django_db

_SEND_PATH = "khatir.rent.messaging.send_with_fallback"
URL = "/api/v1/rent-requests"


def _reachable_request(**kwargs: object) -> RentRequest:
    """A rent request whose tenant has a reachable linked-user phone."""
    user: User = UserFactory()  # type: ignore[assignment]
    req: RentRequest = RentRequestFactory(**kwargs)  # type: ignore[assignment]
    req.lease.tenant.linked_user = user
    req.lease.tenant.save(update_fields=["linked_user"])
    return req


# ── send_rent_link service ──────────────────────────────────────────────────


def test_send_whatsapp() -> None:
    """A successful WhatsApp send stamps sent_via/sent_at and keeps status sent."""
    req = _reachable_request(sent_at=None)

    with mock.patch(_SEND_PATH, return_value=CoreChannel.WHATSAPP) as send:
        send_rent_link(req)

    send.assert_called_once()
    req.refresh_from_db()
    assert req.sent_via == CoreChannel.WHATSAPP.value
    assert req.sent_at is not None
    assert req.status == RentRequestStatus.SENT


def test_status_sent_on_send() -> None:
    """A request left in a non-sent status is recovered to sent on a send."""
    req = _reachable_request(status=RentRequestStatus.REJECTED, sent_at=None)

    with mock.patch(_SEND_PATH, return_value=CoreChannel.WHATSAPP):
        send_rent_link(req)

    req.refresh_from_db()
    assert req.status == RentRequestStatus.SENT


def test_message_carries_public_link_and_is_bilingual() -> None:
    """The body comes from the rent_reminder_due template: link + both languages.

    EPIC-15.T-006 sources the copy from the admin-editable
    ``rent_reminder_due`` template, so the body carries the rendered English and
    Bangla wording (and the public link) rather than a hard-coded string.
    """
    req = RentRequestFactory(link_token="tok_msg", period="2026-07")
    link = _public_link(req.link_token)
    body = _render_message(req, link)

    assert "/r/tok_msg" in link
    assert link in body
    assert "Please pay using this link" in body  # English (template copy)
    assert "ভাড়া" in body  # Bangla
    # Variables are interpolated, not left as raw {placeholder} tokens.
    assert "{payment_link}" not in body
    assert req.lease.tenant.name in body


def test_missing_contact_raises() -> None:
    """No tenant contact → ValidationError so callers can flag, not silently drop."""
    req: RentRequest = RentRequestFactory(sent_at=None)  # type: ignore[assignment]

    with pytest.raises(ValidationError):
        send_rent_link(req)


def test_sms_fallback(settings: pytest.FixtureRequest) -> None:
    """In prod, an unconfigured WhatsApp falls back to a configured SMS gateway."""
    settings.DJANGO_ENV = "prod"  # type: ignore[attr-defined]
    settings.WHATSAPP_API_URL = ""  # type: ignore[attr-defined]  # WhatsApp unconfigured → raises upstream
    settings.WHATSAPP_API_TOKEN = ""  # type: ignore[attr-defined]
    settings.WHATSAPP_PHONE_ID = ""  # type: ignore[attr-defined]
    settings.SMS_GATEWAY_URL = "https://sms.example.test/send"  # type: ignore[attr-defined]
    settings.SMS_GATEWAY_KEY = "test-key"  # type: ignore[attr-defined]
    req = _reachable_request(sent_at=None)

    # Patch the transport so the SMS leg "succeeds" without a network call.
    with mock.patch("khatir.messaging.senders._post_json", return_value=None):
        send_rent_link(req)

    req.refresh_from_db()
    assert req.sent_via == CoreChannel.SMS.value
    assert req.sent_at is not None


def test_reminder_send_bumps_counters() -> None:
    """A reminder send bumps reminder_count and stamps last_reminded_at."""
    req = _reachable_request(reminder_count=0, sent_at=None)

    with mock.patch(_SEND_PATH, return_value=CoreChannel.WHATSAPP):
        send_rent_link(req, is_reminder=True)

    req.refresh_from_db()
    assert req.reminder_count == 1
    assert req.last_reminded_at is not None


# ── POST /{id}/send endpoint ─────────────────────────────────────────────────


@pytest.fixture
def landlord() -> User:
    created: User = UserFactory(  # type: ignore[assignment]
        phone="+8801712345678", name="Landlord", role=Role.LANDLORD
    )
    return created


@pytest.fixture
def client(landlord: User) -> APIClient:
    api = APIClient()
    api.force_authenticate(user=landlord)
    return api


def _own_request(landlord: User) -> RentRequest:
    tenant_user: User = UserFactory()  # type: ignore[assignment]
    lease = LeaseFactory(landlord=landlord)
    lease.tenant.linked_user = tenant_user
    lease.tenant.save(update_fields=["linked_user"])
    req: RentRequest = RentRequestFactory(  # type: ignore[assignment]
        lease=lease, link_token="tok_own_send", sent_at=None
    )
    return req


def test_send_endpoint_delivers_and_audits(client: APIClient, landlord: User) -> None:
    req = _own_request(landlord)

    with mock.patch(_SEND_PATH, return_value=CoreChannel.WHATSAPP) as send:
        resp = client.post(f"{URL}/{req.pk}/send")

    assert resp.status_code == status.HTTP_200_OK
    send.assert_called_once()
    assert resp.data["status"] == RentRequestStatus.SENT.value
    assert resp.data["sent_via"] == CoreChannel.WHATSAPP.value
    assert resp.data["sent_at"] is not None
    assert AuditEntry.objects.filter(
        action="rent.request.send", target_id=str(req.pk)
    ).exists()


def test_send_foreign_request_is_404(client: APIClient) -> None:
    other = LeaseFactory(landlord=UserFactory(role=Role.LANDLORD))
    req = RentRequestFactory(lease=other, link_token="tok_foreign_send")

    with mock.patch(_SEND_PATH, return_value=CoreChannel.WHATSAPP) as send:
        resp = client.post(f"{URL}/{req.pk}/send")

    assert resp.status_code == status.HTTP_404_NOT_FOUND
    send.assert_not_called()


def test_send_anonymous_is_rejected() -> None:
    req = RentRequestFactory(link_token="tok_anon_send")
    api = APIClient()
    resp = api.post(f"{URL}/{req.pk}/send")
    assert resp.status_code in (
        status.HTTP_401_UNAUTHORIZED,
        status.HTTP_403_FORBIDDEN,
    )
