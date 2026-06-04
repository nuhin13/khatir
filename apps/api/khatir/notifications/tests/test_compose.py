"""Tests for the notification compose + schedule service (EPIC-15 T-002).

Celery runs eager in the test settings, so a *now* compose enqueues the (named)
delivery task immediately; we patch ``current_app.send_task`` to assert the
hand-off without depending on T-003's task module existing. Scheduled/recurring
composes are asserted via the Celery-Beat rows they create.
"""

from __future__ import annotations

from decimal import Decimal
from unittest import mock

import pytest
from django.utils import timezone
from django_celery_beat.models import ClockedSchedule, CrontabSchedule, PeriodicTask

from khatir.admin_portal.models import AdminAuditEntry
from khatir.admin_portal.tests.factories import AdminUserFactory
from khatir.core.enums import Role
from khatir.core.exceptions import ValidationError
from khatir.core.models import SystemConfig
from khatir.notifications import services
from khatir.notifications.enums import (
    NotificationAudienceType,
    NotificationScheduleType,
    NotificationStatus,
)
from khatir.notifications.models import Notification

pytestmark = pytest.mark.django_db

CONTENT = {
    "title_en": "Hello",
    "title_bn": "হ্যালো",
    "body_en": "Body",
    "body_bn": "বিষয়",
}


def _compose(**overrides):
    kwargs = {
        "admin_user": None,
        "audience_type": NotificationAudienceType.ALL,
        "audience_filter": {},
        "channels": ["inapp"],
        "content": CONTENT,
        "schedule_type": NotificationScheduleType.NOW,
    }
    kwargs.update(overrides)
    return services.compose_notification(**kwargs)


# ── audience resolution + reach ──────────────────────────────────────────


def test_reach_all_counts_active_users(django_user_model):
    django_user_model.objects.create_user(phone="+8801700000001", role=Role.TENANT)
    django_user_model.objects.create_user(phone="+8801700000002", role=Role.LANDLORD)
    inactive = django_user_model.objects.create_user(phone="+8801700000003")
    inactive.is_active = False
    inactive.save(update_fields=["is_active"])

    with mock.patch.object(services.current_app, "send_task"):
        result = _compose()

    assert result.reach == 2


def test_reach_role_filters(django_user_model):
    django_user_model.objects.create_user(phone="+8801700000010", role=Role.TENANT)
    django_user_model.objects.create_user(phone="+8801700000011", role=Role.TENANT)
    django_user_model.objects.create_user(phone="+8801700000012", role=Role.LANDLORD)

    with mock.patch.object(services.current_app, "send_task"):
        result = _compose(
            audience_type=NotificationAudienceType.ROLE,
            audience_filter={"role": Role.TENANT.value},
        )

    assert result.reach == 2
    assert result.notification.audience_filter == {"role": "tenant"}


def test_reach_specific_user_ids(django_user_model):
    u1 = django_user_model.objects.create_user(phone="+8801700000020")
    u2 = django_user_model.objects.create_user(phone="+8801700000021")
    django_user_model.objects.create_user(phone="+8801700000022")

    with mock.patch.object(services.current_app, "send_task"):
        result = _compose(
            audience_type=NotificationAudienceType.SPECIFIC,
            audience_filter={"user_ids": [u1.pk, u2.pk]},
        )

    assert result.reach == 2


def test_role_audience_rejects_unknown_role():
    with pytest.raises(ValidationError):
        _compose(
            audience_type=NotificationAudienceType.ROLE,
            audience_filter={"role": "wizard"},
        )


def test_specific_audience_requires_user_ids():
    with pytest.raises(ValidationError):
        _compose(
            audience_type=NotificationAudienceType.SPECIFIC,
            audience_filter={},
        )


def test_unknown_audience_type_rejected():
    with pytest.raises(ValidationError):
        _compose(audience_type="galaxy")


# ── channels + content validation ────────────────────────────────────────


def test_empty_channels_rejected():
    with pytest.raises(ValidationError):
        _compose(channels=[])


def test_unknown_channel_rejected():
    with pytest.raises(ValidationError):
        _compose(channels=["pigeon"])


def test_channels_deduplicated():
    with mock.patch.object(services.current_app, "send_task"):
        result = _compose(channels=["sms", "sms", "inapp"])
    assert result.notification.channels == ["sms", "inapp"]


def test_missing_content_field_rejected():
    with pytest.raises(ValidationError):
        _compose(content={**CONTENT, "title_en": ""})


# ── cost estimate ────────────────────────────────────────────────────────


def test_cost_estimate_reads_config(django_user_model):
    django_user_model.objects.create_user(phone="+8801700000030")
    django_user_model.objects.create_user(phone="+8801700000031")
    SystemConfig.objects.update_or_create(
        key="sms_cost_per_message",
        defaults={"value": "0.50", "type": "money"},
    )

    with mock.patch.object(services.current_app, "send_task"):
        result = _compose(channels=["sms", "inapp"])

    # 2 recipients × (0.50 sms + 0 inapp)
    assert result.estimated_cost == Decimal("1.00")


def test_cost_zero_when_unconfigured(django_user_model):
    django_user_model.objects.create_user(phone="+8801700000040")
    with mock.patch.object(services.current_app, "send_task"):
        result = _compose(channels=["inapp"])
    assert result.estimated_cost == Decimal("0")


# ── now: enqueue delivery ────────────────────────────────────────────────


def test_now_enqueues_delivery_task(
    django_user_model, django_capture_on_commit_callbacks
):
    django_user_model.objects.create_user(phone="+8801700000050")
    with mock.patch.object(services.current_app, "send_task") as send_task:
        with django_capture_on_commit_callbacks(execute=True):
            result = _compose()

    send_task.assert_called_once_with(
        services._DELIVER_TASK, args=[result.notification.pk]
    )
    assert result.notification.status == NotificationStatus.SENDING


# ── scheduled: clocked beat row ──────────────────────────────────────────


def test_scheduled_creates_clocked_periodic_task():
    run_at = timezone.now() + timezone.timedelta(hours=2)
    with mock.patch.object(services.current_app, "send_task") as send_task:
        result = _compose(
            schedule_type=NotificationScheduleType.SCHEDULED,
            scheduled_at=run_at,
        )

    send_task.assert_not_called()
    assert result.notification.status == NotificationStatus.SCHEDULED
    assert result.notification.scheduled_at == run_at
    task = PeriodicTask.objects.get(
        name=f"notification-{result.notification.pk}-clocked"
    )
    assert task.one_off is True
    assert task.task == services._DELIVER_TASK
    assert ClockedSchedule.objects.filter(clocked_time=run_at).exists()


def test_scheduled_requires_future_time():
    past = timezone.now() - timezone.timedelta(hours=1)
    with pytest.raises(ValidationError):
        _compose(
            schedule_type=NotificationScheduleType.SCHEDULED,
            scheduled_at=past,
        )


def test_scheduled_requires_scheduled_at():
    with pytest.raises(ValidationError):
        _compose(schedule_type=NotificationScheduleType.SCHEDULED)


# ── recurring: crontab beat row ──────────────────────────────────────────


def test_recurring_creates_crontab_periodic_task():
    with mock.patch.object(services.current_app, "send_task"):
        result = _compose(
            schedule_type=NotificationScheduleType.RECURRING,
            recurrence={"minute": "0", "hour": "9"},
        )

    task = PeriodicTask.objects.get(
        name=f"notification-{result.notification.pk}-recurring"
    )
    assert task.task == services._DELIVER_TASK
    assert CrontabSchedule.objects.filter(minute="0", hour="9").exists()


def test_recurring_requires_recurrence():
    with pytest.raises(ValidationError):
        _compose(schedule_type=NotificationScheduleType.RECURRING)


# ── persistence + audit ──────────────────────────────────────────────────


def test_creates_notification_row_with_content():
    with mock.patch.object(services.current_app, "send_task"):
        result = _compose()
    row = Notification.objects.get(pk=result.notification.pk)
    assert row.title_en == "Hello"
    assert row.body_bn == "বিষয়"


def test_audit_entry_written():
    admin = AdminUserFactory()
    with mock.patch.object(services.current_app, "send_task"):
        result = _compose(admin_user=admin)

    entry = AdminAuditEntry.objects.get(action="notification.compose")
    assert entry.admin_user_id == admin.pk
    assert entry.entity_type == "notifications.notification"
    assert entry.entity_id == str(result.notification.pk)
    assert entry.after_json["reach"] == result.reach


def test_sender_set_from_admin_user():
    admin = AdminUserFactory()
    with mock.patch.object(services.current_app, "send_task"):
        result = _compose(admin_user=admin)
    assert result.notification.sender_id == admin.pk
