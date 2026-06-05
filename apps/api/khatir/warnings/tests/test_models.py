"""Tests for the ``Warning`` model (T-001 §12)."""

from __future__ import annotations

import pytest

from khatir.accounts.tests.factories import UserFactory
from khatir.warnings.enums import WarningType
from khatir.warnings.models import Warning

from .factories import WarningFactory

pytestmark = pytest.mark.django_db


def test_warning_create() -> None:
    warning: Warning = WarningFactory(  # type: ignore[assignment]
        warning_type=WarningType.LATE_RENT,
        reason="Rent overdue 14 days",
    )
    assert warning.pk is not None
    assert warning.lease_id is not None
    assert warning.tenant_id is not None
    assert warning.landlord_id is not None
    assert warning.warning_type == WarningType.LATE_RENT
    assert warning.reason == "Rent overdue 14 days"
    # Defaults / nullable fields.
    assert warning.issued_at is not None
    assert warning.notice_ref == ""
    assert warning.acknowledged_at is None
    assert warning.deleted_at is None


def test_warning_default_type_is_other() -> None:
    warning: Warning = Warning.objects.create(  # type: ignore[assignment]
        lease=WarningFactory().lease,
        tenant=WarningFactory().tenant,
        landlord=UserFactory(),
        reason="Unspecified",
    )
    assert warning.warning_type == WarningType.OTHER


def test_warning_for_user_scopes_to_issuing_landlord() -> None:
    """A warning is private to its issuing landlord — no cross-landlord view."""
    landlord_a = UserFactory(phone="+8801711111111")
    landlord_b = UserFactory(phone="+8801722222222")
    mine: Warning = WarningFactory(landlord=landlord_a)  # type: ignore[assignment]
    WarningFactory(landlord=landlord_b)

    visible = list(Warning.objects.for_user(landlord_a))
    assert visible == [mine]
    # The other landlord cannot see it.
    assert mine not in list(Warning.objects.for_user(landlord_b))


def test_warning_for_user_anonymous_sees_nothing() -> None:
    WarningFactory()
    assert list(Warning.objects.for_user(None)) == []


def test_warning_soft_delete_hidden_from_default_manager() -> None:
    warning: Warning = WarningFactory()  # type: ignore[assignment]
    landlord = warning.landlord
    warning.delete()  # SoftDeleteModel.delete() sets deleted_at.
    assert warning.pk not in Warning.objects.for_user(landlord).values_list(
        "pk", flat=True
    )
