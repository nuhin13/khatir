"""Tests for ``FeatureFlag`` and ``KillSwitchEvent`` models (T-001 §12)."""

from __future__ import annotations

import pytest
from django.db import IntegrityError, models

from khatir.featureflags.enums import FlagScope, KillSwitchAction
from khatir.featureflags.models import FeatureFlag, KillSwitchEvent

from .factories import FeatureFlagFactory, KillSwitchEventFactory

pytestmark = pytest.mark.django_db


# ── FeatureFlag ──────────────────────────────────────────────────────────────


def test_flag_create() -> None:
    flag: FeatureFlag = FeatureFlagFactory(key="nid_ocr_enabled")  # type: ignore[assignment]
    assert flag.pk is not None
    assert flag.key == "nid_ocr_enabled"
    assert flag.enabled is False
    assert flag.scope == FlagScope.GLOBAL
    assert flag.value_json is None
    assert flag.updated_by_id is None
    assert str(flag) == "nid_ocr_enabled [global] off"


def test_flag_enabled_repr() -> None:
    flag: FeatureFlag = FeatureFlagFactory(key="beta_payments", enabled=True)  # type: ignore[assignment]
    assert str(flag) == "beta_payments [global] on"


def test_flag_key_is_unique() -> None:
    FeatureFlagFactory(key="unique_flag")
    with pytest.raises(IntegrityError):
        FeatureFlagFactory(key="unique_flag")


def test_flag_scope_values_match_spec() -> None:
    assert set(FlagScope.values) == {"global", "role", "user"}


def test_flag_value_json_optional() -> None:
    flag: FeatureFlag = FeatureFlagFactory(value_json={"max_retries": 3})  # type: ignore[assignment]
    flag.refresh_from_db()
    assert flag.value_json == {"max_retries": 3}


def test_flag_updated_by_is_nullable() -> None:
    field = FeatureFlag._meta.get_field("updated_by")
    assert isinstance(field, models.ForeignKey)
    assert field.null is True
    assert field.remote_field.on_delete is models.SET_NULL


def test_flag_updated_by_fk_points_to_admin_user() -> None:
    field = FeatureFlag._meta.get_field("updated_by")
    assert isinstance(field, models.ForeignKey)
    assert field.related_model.__name__ == "AdminUser"


def test_flag_scope_index_present() -> None:
    index_fields = {tuple(idx.fields) for idx in FeatureFlag._meta.indexes}
    assert ("scope", "enabled") in index_fields


def test_flag_timestamps_auto_set() -> None:
    flag: FeatureFlag = FeatureFlagFactory()  # type: ignore[assignment]
    assert flag.created_at is not None
    assert flag.updated_at is not None


# ── KillSwitchEvent ───────────────────────────────────────────────────────────


def test_killswitch_create() -> None:
    event: KillSwitchEvent = KillSwitchEventFactory(  # type: ignore[assignment]
        switch_key="payment_gateway",
        action=KillSwitchAction.DISABLE,
        reason="Suspicious traffic spike.",
    )
    assert event.pk is not None
    assert event.switch_key == "payment_gateway"
    assert event.action == KillSwitchAction.DISABLE
    assert event.reason == "Suspicious traffic spike."
    assert event.admin_user_id is None
    assert event.lawyer_reference == ""
    assert event.created_at is not None


def test_killswitch_action_values_match_spec() -> None:
    assert set(KillSwitchAction.values) == {"disable", "enable"}


def test_killswitch_immutable_update_raises() -> None:
    """Saving an existing KillSwitchEvent must raise TypeError (§11 + §15)."""
    event: KillSwitchEvent = KillSwitchEventFactory()  # type: ignore[assignment]
    event.reason = "Edited reason"
    with pytest.raises(TypeError, match="immutable"):
        event.save()


def test_killswitch_immutable_delete_raises() -> None:
    """Deleting a KillSwitchEvent must raise TypeError."""
    event: KillSwitchEvent = KillSwitchEventFactory()  # type: ignore[assignment]
    with pytest.raises(TypeError, match="cannot be deleted"):
        event.delete()


def test_killswitch_admin_user_is_nullable() -> None:
    field = KillSwitchEvent._meta.get_field("admin_user")
    assert isinstance(field, models.ForeignKey)
    assert field.null is True
    assert field.remote_field.on_delete is models.SET_NULL


def test_killswitch_admin_user_fk_points_to_admin_user() -> None:
    field = KillSwitchEvent._meta.get_field("admin_user")
    assert isinstance(field, models.ForeignKey)
    assert field.related_model.__name__ == "AdminUser"


def test_killswitch_str() -> None:
    event: KillSwitchEvent = KillSwitchEventFactory(  # type: ignore[assignment]
        switch_key="ocr_service",
        action=KillSwitchAction.ENABLE,
    )
    # __str__ includes the switch_key and action
    assert "ocr_service" in str(event)
    assert "enable" in str(event)


def test_killswitch_created_at_is_auto() -> None:
    field = KillSwitchEvent._meta.get_field("created_at")
    assert isinstance(field, models.DateTimeField)
    assert field.auto_now_add is True


def test_killswitch_index_on_switch_key_created_at() -> None:
    index_fields = {tuple(idx.fields) for idx in KillSwitchEvent._meta.indexes}
    assert ("switch_key", "created_at") in index_fields


def test_killswitch_no_updated_at() -> None:
    """KillSwitchEvent must NOT have an updated_at column (immutable record)."""
    field_names = {f.name for f in KillSwitchEvent._meta.get_fields()}
    assert "updated_at" not in field_names
