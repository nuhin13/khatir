"""Tests for the notification delivery Celery tasks (EPIC-15 T-003).

Celery runs eager in the test settings, so :func:`deliver_notification`'s
``send_task`` fan-out executes :func:`deliver_to_recipient` synchronously — the
whole delivery path runs in-process. The channel sender is mocked throughout so
no WhatsApp/SMS/email account is needed.
"""

from __future__ import annotations

from unittest import mock

import pytest

from khatir.accounts.tests.factories import UserFactory
from khatir.core.enums import Channel, Language, Role
from khatir.notifications import tasks
from khatir.notifications.enums import (
    NotificationAudienceType,
    NotificationDeliveryStatus,
    NotificationScheduleType,
    NotificationStatus,
)
from khatir.notifications.models import Notification, NotificationDelivery
from khatir.notifications.tests.factories import NotificationFactory

pytestmark = pytest.mark.django_db


def _notification(**overrides) -> Notification:
    kwargs = {
        "status": NotificationStatus.SENDING,
        "schedule_type": NotificationScheduleType.NOW,
        "audience_type": NotificationAudienceType.ALL,
        "channels": ["inapp"],
    }
    kwargs.update(overrides)
    return NotificationFactory(**kwargs)


# ── fan-out: deliver_notification ────────────────────────────────────────


def test_fans_out_one_subtask_per_recipient_per_channel():
    UserFactory(phone="+8801700000100", is_active=True)
    UserFactory(phone="+8801700000101", is_active=True)
    notification = _notification(channels=["inapp", "sms"])

    with mock.patch.object(tasks, "get_sender") as get_sender:
        dispatched = tasks.deliver_notification(notification.pk)

    # 2 recipients × 2 channels
    assert dispatched == 4
    assert NotificationDelivery.objects.filter(notification=notification).count() == 4
    assert get_sender.called


def test_fan_out_marks_notification_sent():
    UserFactory(phone="+8801700000110", is_active=True)
    notification = _notification()

    with mock.patch.object(tasks, "get_sender"):
        tasks.deliver_notification(notification.pk)

    notification.refresh_from_db()
    assert notification.status == NotificationStatus.SENT


def test_fan_out_skips_inactive_users():
    UserFactory(phone="+8801700000120", is_active=True)
    UserFactory(phone="+8801700000121", is_active=False)
    notification = _notification()

    with mock.patch.object(tasks, "get_sender"):
        dispatched = tasks.deliver_notification(notification.pk)

    assert dispatched == 1


def test_fan_out_resolves_role_audience():
    UserFactory(phone="+8801700000130", role=Role.TENANT, is_active=True)
    UserFactory(phone="+8801700000131", role=Role.TENANT, is_active=True)
    UserFactory(phone="+8801700000132", role=Role.LANDLORD, is_active=True)
    notification = _notification(
        audience_type=NotificationAudienceType.ROLE,
        audience_filter={"role": Role.TENANT.value},
    )

    with mock.patch.object(tasks, "get_sender"):
        dispatched = tasks.deliver_notification(notification.pk)

    assert dispatched == 2


def test_fan_out_specific_audience():
    u1 = UserFactory(phone="+8801700000140", is_active=True)
    UserFactory(phone="+8801700000141", is_active=True)
    notification = _notification(
        audience_type=NotificationAudienceType.SPECIFIC,
        audience_filter={"user_ids": [u1.pk]},
    )

    with mock.patch.object(tasks, "get_sender"):
        dispatched = tasks.deliver_notification(notification.pk)

    assert dispatched == 1


def test_bad_audience_fails_closed_not_crash():
    UserFactory(phone="+8801700000150", is_active=True)
    notification = _notification(
        audience_type=NotificationAudienceType.SPECIFIC,
        audience_filter={},  # malformed: no user_ids
    )

    with mock.patch.object(tasks, "get_sender") as get_sender:
        dispatched = tasks.deliver_notification(notification.pk)

    assert dispatched == 0
    get_sender.assert_not_called()


def test_missing_notification_is_noop():
    with mock.patch.object(tasks, "get_sender") as get_sender:
        assert tasks.deliver_notification(999_999) == 0
    get_sender.assert_not_called()


# ── per-recipient: deliver_to_recipient ──────────────────────────────────


def test_inapp_delivery_marked_delivered_and_counts_bumped():
    user = UserFactory(phone="+8801700000160", is_active=True)
    notification = _notification(channels=["inapp"])

    with mock.patch.object(tasks, "get_sender") as get_sender:
        status = tasks.deliver_to_recipient(notification.pk, user.pk, "inapp")

    assert status == NotificationDeliveryStatus.DELIVERED
    get_sender.return_value.send.assert_called_once()
    delivery = NotificationDelivery.objects.get(notification=notification, user=user)
    assert delivery.status == NotificationDeliveryStatus.DELIVERED
    assert delivery.delivered_at is not None
    notification.refresh_from_db()
    assert notification.sent_count == 1
    assert notification.delivered_count == 1


def test_sms_delivery_marked_sent_not_delivered():
    user = UserFactory(phone="+8801700000170", is_active=True)
    notification = _notification(channels=["sms"])

    with mock.patch.object(tasks, "get_sender"):
        status = tasks.deliver_to_recipient(notification.pk, user.pk, "sms")

    assert status == NotificationDeliveryStatus.SENT
    delivery = NotificationDelivery.objects.get(notification=notification, user=user)
    assert delivery.status == NotificationDeliveryStatus.SENT
    assert delivery.delivered_at is None
    notification.refresh_from_db()
    assert notification.sent_count == 1
    assert notification.delivered_count == 0


def test_sms_recipient_address_is_phone():
    user = UserFactory(phone="+8801700000180", is_active=True)
    notification = _notification(channels=["sms"])

    with mock.patch.object(tasks, "get_sender") as get_sender:
        tasks.deliver_to_recipient(notification.pk, user.pk, "sms")

    args, kwargs = get_sender.return_value.send.call_args
    assert args[0] == "+8801700000180"
    assert kwargs["channel"] == Channel.SMS


def test_sender_failure_marks_delivery_failed():
    from khatir.core.exceptions import UpstreamUnavailableError

    user = UserFactory(phone="+8801700000190", is_active=True)
    notification = _notification(channels=["sms"])

    with mock.patch.object(tasks, "get_sender") as get_sender:
        get_sender.return_value.send.side_effect = UpstreamUnavailableError("down")
        status = tasks.deliver_to_recipient(notification.pk, user.pk, "sms")

    assert status == NotificationDeliveryStatus.FAILED
    delivery = NotificationDelivery.objects.get(notification=notification, user=user)
    assert delivery.status == NotificationDeliveryStatus.FAILED
    assert "down" in delivery.error
    notification.refresh_from_db()
    assert notification.sent_count == 0


def test_delivery_is_idempotent_no_duplicate_rows():
    user = UserFactory(phone="+8801700000200", is_active=True)
    notification = _notification(channels=["inapp"])

    with mock.patch.object(tasks, "get_sender"):
        tasks.deliver_to_recipient(notification.pk, user.pk, "inapp")
        tasks.deliver_to_recipient(notification.pk, user.pk, "inapp")

    assert (
        NotificationDelivery.objects.filter(
            notification=notification, user=user, channel="inapp"
        ).count()
        == 1
    )


def test_render_uses_recipient_language():
    user = UserFactory(phone="+8801700000210", is_active=True, language=Language.EN)
    notification = _notification(
        channels=["sms"],
        title_en="English title",
        body_en="English body",
        title_bn="বাংলা",
        body_bn="বিষয়",
    )

    with mock.patch.object(tasks, "get_sender") as get_sender:
        tasks.deliver_to_recipient(notification.pk, user.pk, "sms")

    message = get_sender.return_value.send.call_args.args[1]
    assert "English title" in message
    assert "English body" in message


def test_render_defaults_to_bangla():
    user = UserFactory(phone="+8801700000220", is_active=True, language=Language.BN)
    notification = _notification(
        channels=["sms"],
        title_bn="বাংলা শিরোনাম",
        body_bn="বাংলা বিষয়",
    )

    with mock.patch.object(tasks, "get_sender") as get_sender:
        tasks.deliver_to_recipient(notification.pk, user.pk, "sms")

    message = get_sender.return_value.send.call_args.args[1]
    assert "বাংলা শিরোনাম" in message
