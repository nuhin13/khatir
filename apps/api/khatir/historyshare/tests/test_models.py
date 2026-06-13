"""Tests for the ``HistoryShare`` model (T-001 §12)."""

from __future__ import annotations

import datetime

import pytest
from django.db import models
from django.utils import timezone

from khatir.historyshare.models import HistoryShare

from .factories import HistoryShareFactory

pytestmark = pytest.mark.django_db


def test_history_share_create() -> None:
    share: HistoryShare = HistoryShareFactory()  # type: ignore[assignment]
    assert share.pk is not None
    assert share.tenant_id is not None
    assert share.recipient_landlord_id is not None
    assert share.consent_record_id is not None
    assert share.expires_at is None
    assert share.revoked_at is None
    assert share.created_at is not None
    assert str(share) != ""


def test_history_share_timestamps_present() -> None:
    share: HistoryShare = HistoryShareFactory()  # type: ignore[assignment]
    assert share.created_at is not None
    assert share.updated_at is not None


def test_history_share_tenant_fk_protect() -> None:
    field = HistoryShare._meta.get_field("tenant")
    assert isinstance(field, models.ForeignKey)
    assert field.remote_field.on_delete is models.PROTECT


def test_history_share_consent_record_fk_protect() -> None:
    field = HistoryShare._meta.get_field("consent_record")
    assert isinstance(field, models.ForeignKey)
    assert field.remote_field.on_delete is models.PROTECT


def test_history_share_recipient_landlord_fk_protect() -> None:
    field = HistoryShare._meta.get_field("recipient_landlord")
    assert isinstance(field, models.ForeignKey)
    assert field.remote_field.on_delete is models.PROTECT


def test_history_share_scope_and_stats_are_json() -> None:
    field_scope = HistoryShare._meta.get_field("scope")
    field_stats = HistoryShare._meta.get_field("factual_stats")
    assert isinstance(field_scope, models.JSONField)
    assert isinstance(field_stats, models.JSONField)


def test_history_share_has_no_subjective_field() -> None:
    """Structural guarantee: no rating/score/opinion column exists."""
    field_names = {f.name for f in HistoryShare._meta.get_fields()}
    forbidden = {"rating", "score", "opinion", "review", "comment", "feedback", "stars"}
    assert field_names.isdisjoint(forbidden)


def test_history_share_indexes() -> None:
    index_fields = {tuple(idx.fields) for idx in HistoryShare._meta.indexes}
    assert ("tenant",) in index_fields
    assert ("recipient_landlord",) in index_fields


# --- is_active: consent / expiry / revoke enforcement ------------------------


def test_is_active_default_share_is_active() -> None:
    share: HistoryShare = HistoryShareFactory()  # type: ignore[assignment]
    assert share.is_active() is True


def test_is_active_false_when_revoked() -> None:
    share: HistoryShare = HistoryShareFactory(revoked_at=timezone.now())  # type: ignore[assignment]
    assert share.is_active() is False


def test_is_active_false_when_expired() -> None:
    past = timezone.now() - datetime.timedelta(days=1)
    share: HistoryShare = HistoryShareFactory(expires_at=past)  # type: ignore[assignment]
    assert share.is_active() is False


def test_is_active_true_when_expiry_in_future() -> None:
    future = timezone.now() + datetime.timedelta(days=30)
    share: HistoryShare = HistoryShareFactory(expires_at=future)  # type: ignore[assignment]
    assert share.is_active() is True
