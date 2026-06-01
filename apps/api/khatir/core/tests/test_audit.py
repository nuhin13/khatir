"""Tests for the audit writer."""

import pytest
from django.contrib.auth.models import User

from khatir.core.audit import audit
from khatir.core.models import AuditEntry, SystemConfig

pytestmark = pytest.mark.django_db


def test_audit_writes_entry_with_actor_and_target() -> None:
    actor = User.objects.create(username="landlord")
    target = SystemConfig.objects.create(key="k", value="1", type="int")

    entry = audit(
        actor=actor,
        action="config.update",
        target=target,
        before={"value": "0"},
        after={"value": "1"},
    )

    assert isinstance(entry, AuditEntry)
    assert entry.actor == actor
    assert entry.action == "config.update"
    assert entry.target_type == "core.systemconfig"
    assert entry.target_id == str(target.pk)
    assert entry.before == {"value": "0"}
    assert entry.after == {"value": "1"}


def test_audit_system_action_without_actor() -> None:
    entry = audit(actor=None, action="system.cron", target=None)
    assert entry.actor is None
    assert entry.target_type == ""
    assert entry.target_id == ""


def test_audit_persists() -> None:
    audit(actor=None, action="tenant.create")
    assert AuditEntry.objects.filter(action="tenant.create").count() == 1
