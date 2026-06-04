"""Verify the 3 system ``NotificationTemplate`` rows seeded by
0002_seed_system_templates (EPIC-15.T-005).

The data migration runs as part of the test-DB setup, so the rows are present
without re-invoking it. Keys, trigger events, and channel sets mirror the task
spec: rent_reminder_due (rent_due, whatsapp+sms), rent_receipt_generated
(payment_verified, whatsapp+sms), welcome_new_user (user_created, inapp).
"""

from __future__ import annotations

import pytest

from khatir.notifications.models import NotificationTemplate

pytestmark = pytest.mark.django_db

EXPECTED_KEYS = {
    "rent_reminder_due",
    "rent_receipt_generated",
    "welcome_new_user",
}


def test_three_system_templates_seeded() -> None:
    seeded = set(NotificationTemplate.objects.values_list("key", flat=True))
    assert EXPECTED_KEYS <= seeded
    assert NotificationTemplate.objects.filter(key__in=EXPECTED_KEYS).count() == 3


def test_rent_reminder_due_template() -> None:
    tmpl = NotificationTemplate.objects.get(key="rent_reminder_due")
    assert tmpl.trigger_event == "rent_due"
    assert tmpl.channels == ["whatsapp", "sms"]
    assert tmpl.active is True
    assert tmpl.title_en and tmpl.title_bn
    assert tmpl.body_en and tmpl.body_bn
    assert "tenant_name" in tmpl.variables
    assert "amount" in tmpl.variables


def test_rent_receipt_generated_template() -> None:
    tmpl = NotificationTemplate.objects.get(key="rent_receipt_generated")
    assert tmpl.trigger_event == "payment_verified"
    assert tmpl.channels == ["whatsapp", "sms"]
    assert tmpl.active is True
    assert "receipt_link" in tmpl.variables


def test_welcome_new_user_template() -> None:
    tmpl = NotificationTemplate.objects.get(key="welcome_new_user")
    assert tmpl.trigger_event == "user_created"
    assert tmpl.channels == ["inapp"]
    assert tmpl.active is True
    assert tmpl.variables == ["user_name"]


def test_all_seeded_templates_are_bilingual() -> None:
    for tmpl in NotificationTemplate.objects.filter(key__in=EXPECTED_KEYS):
        assert tmpl.title_en, tmpl.key
        assert tmpl.title_bn, tmpl.key
        assert tmpl.body_en, tmpl.key
        assert tmpl.body_bn, tmpl.key
        # Bangla copy should differ from English copy.
        assert tmpl.title_en != tmpl.title_bn, tmpl.key
        assert tmpl.body_en != tmpl.body_bn, tmpl.key


def test_body_placeholders_match_declared_variables() -> None:
    """Every declared variable must appear as a {placeholder} in both bodies."""
    for tmpl in NotificationTemplate.objects.filter(key__in=EXPECTED_KEYS):
        for var in tmpl.variables:
            token = "{" + var + "}"
            assert token in tmpl.body_en, (tmpl.key, var)
            assert token in tmpl.body_bn, (tmpl.key, var)


def test_seed_is_idempotent() -> None:
    """Re-running the seed must not duplicate rows (update_or_create)."""
    from importlib import import_module

    from django.apps import apps as django_apps

    module = import_module(
        "khatir.notifications.migrations.0002_seed_system_templates"
    )
    module.seed_system_templates(django_apps, None)
    assert NotificationTemplate.objects.filter(key__in=EXPECTED_KEYS).count() == 3
