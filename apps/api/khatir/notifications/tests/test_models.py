"""Tests for Notification, NotificationDelivery, NotificationTemplate models."""

from __future__ import annotations

import pytest
from django.db import models

from khatir.core.enums import Channel
from khatir.notifications.enums import (
    NotificationAudienceType,
    NotificationDeliveryStatus,
    NotificationScheduleType,
    NotificationStatus,
)
from khatir.notifications.models import (
    Notification,
    NotificationDelivery,
    NotificationTemplate,
)

from .factories import (
    NotificationDeliveryFactory,
    NotificationFactory,
    NotificationTemplateFactory,
)

pytestmark = pytest.mark.django_db


# ---------------------------------------------------------------------------
# Notification
# ---------------------------------------------------------------------------


def test_notification_create() -> None:
    notif: Notification = NotificationFactory(  # type: ignore[assignment]
        title_en="Test Notification",
        title_bn="পরীক্ষামূলক বিজ্ঞপ্তি",
    )
    assert notif.pk is not None
    assert notif.title_en == "Test Notification"
    assert notif.title_bn == "পরীক্ষামূলক বিজ্ঞপ্তি"
    assert notif.status == NotificationStatus.DRAFT
    assert notif.audience_type == NotificationAudienceType.ALL
    assert notif.schedule_type == NotificationScheduleType.NOW
    assert notif.sender_id is None
    assert str(notif) == "[draft] Test Notification"


def test_notification_default_counts_zero() -> None:
    notif: Notification = NotificationFactory()  # type: ignore[assignment]
    notif.refresh_from_db()
    assert notif.sent_count == 0
    assert notif.delivered_count == 0
    assert notif.opened_count == 0


def test_notification_channels_is_json() -> None:
    notif: Notification = NotificationFactory(  # type: ignore[assignment]
        channels=["inapp", "sms"]
    )
    notif.refresh_from_db()
    assert notif.channels == ["inapp", "sms"]


def test_notification_scheduled_at_nullable() -> None:
    notif: Notification = NotificationFactory()  # type: ignore[assignment]
    notif.refresh_from_db()
    assert notif.scheduled_at is None


def test_notification_audience_filter_default_empty_dict() -> None:
    notif: Notification = NotificationFactory()  # type: ignore[assignment]
    notif.refresh_from_db()
    assert notif.audience_filter == {}


def test_notification_status_values_match_spec() -> None:
    assert set(NotificationStatus.values) == {
        "draft",
        "scheduled",
        "sending",
        "sent",
        "failed",
    }


def test_notification_audience_type_values_match_spec() -> None:
    assert set(NotificationAudienceType.values) == {
        "all",
        "role",
        "segment",
        "specific",
    }


def test_notification_schedule_type_values_match_spec() -> None:
    assert set(NotificationScheduleType.values) == {
        "now",
        "scheduled",
        "recurring",
    }


def test_notification_sender_is_nullable_fk() -> None:
    from khatir.admin_portal.models import AdminUser

    field = Notification._meta.get_field("sender")
    assert isinstance(field, models.ForeignKey)
    assert field.null is True
    assert field.remote_field.on_delete is models.PROTECT
    assert field.related_model is AdminUser


def test_notification_indexes_present() -> None:
    index_fields_sets = {tuple(idx.fields) for idx in Notification._meta.indexes}
    assert ("status",) in index_fields_sets
    assert ("audience_type",) in index_fields_sets
    assert ("schedule_type",) in index_fields_sets


def test_notification_uses_timestamped_model() -> None:
    """Notification inherits TimeStampedModel — has created_at and updated_at."""
    notif: Notification = NotificationFactory()  # type: ignore[assignment]
    assert notif.created_at is not None
    assert notif.updated_at is not None
    # No soft-delete; there is no deleted_at field.
    assert not hasattr(notif, "deleted_at")


# ---------------------------------------------------------------------------
# NotificationDelivery
# ---------------------------------------------------------------------------


def test_delivery_create() -> None:
    delivery: NotificationDelivery = NotificationDeliveryFactory(  # type: ignore[assignment]
        channel=Channel.INAPP
    )
    assert delivery.pk is not None
    assert delivery.channel == Channel.INAPP
    assert delivery.status == NotificationDeliveryStatus.QUEUED
    assert delivery.delivered_at is None
    assert delivery.opened_at is None
    assert delivery.error == ""


def test_delivery_str() -> None:
    delivery: NotificationDelivery = NotificationDeliveryFactory()  # type: ignore[assignment]
    s = str(delivery)
    assert "queued" in s
    assert str(delivery.user_id) in s


def test_delivery_status_values_match_spec() -> None:
    assert set(NotificationDeliveryStatus.values) == {
        "queued",
        "sent",
        "delivered",
        "opened",
        "failed",
    }


def test_delivery_notification_fk_is_cascade() -> None:
    field = NotificationDelivery._meta.get_field("notification")
    assert isinstance(field, models.ForeignKey)
    assert field.remote_field.on_delete is models.CASCADE


def test_delivery_user_fk_is_cascade() -> None:
    field = NotificationDelivery._meta.get_field("user")
    assert isinstance(field, models.ForeignKey)
    assert field.remote_field.on_delete is models.CASCADE


def test_delivery_cascade_on_notification_delete() -> None:
    """Deleting a Notification hard-deletes all its DeliveryRows."""
    delivery: NotificationDelivery = NotificationDeliveryFactory()  # type: ignore[assignment]
    notification = delivery.notification
    delivery_pk = delivery.pk
    notification.delete()
    assert NotificationDelivery.objects.filter(pk=delivery_pk).count() == 0


def test_delivery_index_notification_status_present() -> None:
    index_fields_sets = {tuple(idx.fields) for idx in NotificationDelivery._meta.indexes}
    assert ("notification", "status") in index_fields_sets


def test_delivery_index_user_status_present() -> None:
    index_fields_sets = {tuple(idx.fields) for idx in NotificationDelivery._meta.indexes}
    assert ("user", "status") in index_fields_sets


# ---------------------------------------------------------------------------
# NotificationTemplate
# ---------------------------------------------------------------------------


def test_template_create() -> None:
    tmpl: NotificationTemplate = NotificationTemplateFactory(  # type: ignore[assignment]
        key="rent_reminder",
        trigger_event="rent.due",
    )
    assert tmpl.pk is not None
    assert tmpl.key == "rent_reminder"
    assert tmpl.trigger_event == "rent.due"
    assert tmpl.active is True
    assert str(tmpl) == "rent_reminder"


def test_template_key_is_unique() -> None:
    NotificationTemplateFactory(key="welcome")  # type: ignore[call-arg]
    import django.db
    with pytest.raises(django.db.IntegrityError):
        NotificationTemplateFactory(key="welcome")  # type: ignore[call-arg]


def test_template_variables_default_empty_list() -> None:
    tmpl: NotificationTemplate = NotificationTemplateFactory()  # type: ignore[assignment]
    tmpl.refresh_from_db()
    assert tmpl.variables == []


def test_template_channels_stored_as_json() -> None:
    tmpl: NotificationTemplate = NotificationTemplateFactory(  # type: ignore[assignment]
        channels=["inapp", "whatsapp"]
    )
    tmpl.refresh_from_db()
    assert tmpl.channels == ["inapp", "whatsapp"]


def test_template_active_default_true() -> None:
    tmpl: NotificationTemplate = NotificationTemplateFactory()  # type: ignore[assignment]
    assert tmpl.active is True


def test_template_key_field_unique_and_indexed() -> None:
    field = NotificationTemplate._meta.get_field("key")
    assert isinstance(field, models.CharField)
    assert field.unique is True


def test_template_indexes_present() -> None:
    index_fields_sets = {tuple(idx.fields) for idx in NotificationTemplate._meta.indexes}
    assert ("trigger_event",) in index_fields_sets
    assert ("active",) in index_fields_sets


def test_template_bilingual_fields_present() -> None:
    field_names = {f.name for f in NotificationTemplate._meta.get_fields()}
    assert "title_en" in field_names
    assert "title_bn" in field_names
    assert "body_en" in field_names
    assert "body_bn" in field_names


def test_template_uses_timestamped_model() -> None:
    tmpl: NotificationTemplate = NotificationTemplateFactory()  # type: ignore[assignment]
    assert tmpl.created_at is not None
    assert tmpl.updated_at is not None
    assert not hasattr(tmpl, "deleted_at")
