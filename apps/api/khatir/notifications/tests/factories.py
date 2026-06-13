"""factory-boy factories for the notifications domain.

factory-boy ships no type stubs, so its dynamic attributes are opaque to mypy;
the per-module override in ``pyproject.toml`` relaxes the untyped-call checks.
"""

from __future__ import annotations

import factory

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


class NotificationFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = Notification

    sender = None
    audience_type = NotificationAudienceType.ALL
    audience_filter = factory.LazyFunction(dict)  # type: ignore[attr-defined]
    channels = factory.LazyFunction(lambda: ["inapp"])  # type: ignore[attr-defined]
    title_en = factory.Sequence(lambda n: f"Notification {n}")  # type: ignore[attr-defined]
    title_bn = factory.Sequence(lambda n: f"বিজ্ঞপ্তি {n}")  # type: ignore[attr-defined]
    body_en = factory.Sequence(lambda n: f"Notification body {n}.")  # type: ignore[attr-defined]
    body_bn = factory.Sequence(lambda n: f"বিজ্ঞপ্তির বিষয় {n}।")  # type: ignore[attr-defined]
    schedule_type = NotificationScheduleType.NOW
    scheduled_at = None
    status = NotificationStatus.DRAFT


class NotificationDeliveryFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = NotificationDelivery

    notification = factory.SubFactory(NotificationFactory)  # type: ignore[attr-defined]
    user = factory.SubFactory("khatir.accounts.tests.factories.UserFactory")  # type: ignore[attr-defined]
    channel = "inapp"
    status = NotificationDeliveryStatus.QUEUED
    delivered_at = None
    opened_at = None
    error = ""


class NotificationTemplateFactory(factory.django.DjangoModelFactory):  # type: ignore[type-arg]
    class Meta:
        model = NotificationTemplate

    key = factory.Sequence(lambda n: f"template_{n}")  # type: ignore[attr-defined]
    trigger_event = factory.Sequence(lambda n: f"event.{n}")  # type: ignore[attr-defined]
    channels = factory.LazyFunction(lambda: ["inapp"])  # type: ignore[attr-defined]
    title_en = factory.Sequence(lambda n: f"Template Title {n}")  # type: ignore[attr-defined]
    title_bn = factory.Sequence(lambda n: f"টেমপ্লেট শিরোনাম {n}")  # type: ignore[attr-defined]
    body_en = factory.Sequence(lambda n: f"Template body {n}.")  # type: ignore[attr-defined]
    body_bn = factory.Sequence(lambda n: f"টেমপ্লেট বিষয় {n}।")  # type: ignore[attr-defined]
    variables = factory.LazyFunction(list)  # type: ignore[attr-defined]
    active = True
