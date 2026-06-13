"""Tests for AdminAuditEntry + the ``admin_audit`` writer (T-002 §12).

Covers: write via the writer, entity denormalization, system (null) actor,
IP capture, before/after diffs, and immutability (no update, no delete) at both
the instance and queryset level.
"""

from __future__ import annotations

import pytest
from django.db import models

from khatir.admin_portal.audit import admin_audit
from khatir.admin_portal.models import (
    AdminAuditEntry,
    AdminUser,
    ImmutableAuditError,
)

from .factories import AdminAuditEntryFactory, AdminUserFactory

pytestmark = pytest.mark.django_db


# --- Writer creates rows ----------------------------------------------------


def test_audit_write() -> None:
    admin: AdminUser = AdminUserFactory()  # type: ignore[assignment]
    entry = admin_audit(
        admin_user=admin,
        action="feature_flag.toggle",
        before={"enabled": False},
        after={"enabled": True},
        ip="198.51.100.4",
        reason="Enable beta search",
    )
    assert entry.pk is not None
    assert entry.admin_user_id == admin.pk
    assert entry.action == "feature_flag.toggle"
    assert entry.before_json == {"enabled": False}
    assert entry.after_json == {"enabled": True}
    assert entry.ip == "198.51.100.4"
    assert entry.reason == "Enable beta search"
    assert entry.created_at is not None


def test_audit_denormalizes_entity() -> None:
    admin: AdminUser = AdminUserFactory()  # type: ignore[assignment]
    target: AdminUser = AdminUserFactory()  # type: ignore[assignment]
    entry = admin_audit(
        admin_user=admin,
        action="admin_user.disable",
        entity=target,
        before={"disabled": False},
        after={"disabled": True},
    )
    assert entry.entity_type == "admin_portal.adminuser"
    assert entry.entity_id == str(target.pk)


def test_audit_system_actor_is_null() -> None:
    entry = admin_audit(admin_user=None, action="system.maintenance")
    assert entry.admin_user_id is None


def test_audit_defaults() -> None:
    admin: AdminUser = AdminUserFactory()  # type: ignore[assignment]
    entry = admin_audit(admin_user=admin, action="config.read")
    assert entry.entity_type == ""
    assert entry.entity_id == ""
    assert entry.before_json is None
    assert entry.after_json is None
    assert entry.ip is None
    assert entry.reason == ""


def test_audit_empty_ip_string_stored_as_null() -> None:
    admin: AdminUser = AdminUserFactory()  # type: ignore[assignment]
    entry = admin_audit(admin_user=admin, action="x.y", ip="")
    assert entry.ip is None


# --- Immutability -----------------------------------------------------------


def test_immutable_instance_update_rejected() -> None:
    entry: AdminAuditEntry = AdminAuditEntryFactory()  # type: ignore[assignment]
    entry.reason = "tampered"
    with pytest.raises(ImmutableAuditError):
        entry.save()


def test_immutable_instance_delete_rejected() -> None:
    entry: AdminAuditEntry = AdminAuditEntryFactory()  # type: ignore[assignment]
    with pytest.raises(ImmutableAuditError):
        entry.delete()
    assert AdminAuditEntry.objects.filter(pk=entry.pk).exists()


def test_immutable_queryset_update_rejected() -> None:
    AdminAuditEntryFactory()
    with pytest.raises(ImmutableAuditError):
        AdminAuditEntry.objects.all().update(reason="tampered")


def test_immutable_queryset_delete_rejected() -> None:
    AdminAuditEntryFactory()
    with pytest.raises(ImmutableAuditError):
        AdminAuditEntry.objects.all().delete()
    assert AdminAuditEntry.objects.count() == 1


# --- Field/shape sanity -----------------------------------------------------


def test_before_after_are_jsonfields() -> None:
    assert isinstance(AdminAuditEntry._meta.get_field("before_json"), models.JSONField)
    assert isinstance(AdminAuditEntry._meta.get_field("after_json"), models.JSONField)


def test_ip_is_generic_ip_field() -> None:
    assert isinstance(
        AdminAuditEntry._meta.get_field("ip"), models.GenericIPAddressField
    )


def test_admin_user_fk_set_null_on_delete() -> None:
    field = AdminAuditEntry._meta.get_field("admin_user")
    assert isinstance(field, models.ForeignKey)
    assert field.remote_field.on_delete is models.SET_NULL


def test_str_contains_action() -> None:
    entry: AdminAuditEntry = AdminAuditEntryFactory(action="admin_user.disable")  # type: ignore[assignment]
    assert "admin_user.disable" in str(entry)
