"""Tests for the chatbot's scoped data tools (EPIC-23.T-003).

The headline guarantee is *strict own-data scoping*: a tool only ever reports
the authenticated user's numbers, never another user's, and there is no
parameter through which a caller could ask about someone else's portfolio. These
tests seed a second landlord and assert their data never bleeds into the first
landlord's summary, and they pin the summary numbers against hand-built fixtures.
"""

from __future__ import annotations

from decimal import Decimal

import pytest
from django.contrib.auth.models import AnonymousUser

from khatir.accounts.enums import Role
from khatir.accounts.tests.factories import UserFactory
from khatir.chatbot.context import build_user_context
from khatir.chatbot.tools import (
    PortfolioSummary,
    format_portfolio_summary,
    get_portfolio_summary,
)
from khatir.leases.enums import LeaseStatus, RentScheduleStatus
from khatir.leases.tests.factories import LeaseFactory, RentScheduleFactory
from khatir.properties.enums import UnitStatus
from khatir.properties.tests.factories import BuildingFactory, UnitFactory

pytestmark = pytest.mark.django_db


@pytest.fixture
def landlord():
    return UserFactory(role=Role.LANDLORD)


def _unit(owner, *, status=UnitStatus.OCCUPIED):
    building = BuildingFactory(owner=owner)
    return UnitFactory(building=building, status=status)


def _lease(owner, unit):
    return LeaseFactory(landlord=owner, unit=unit, status=LeaseStatus.ACTIVE)


def test_summary_reflects_own_collection_and_occupancy(landlord):
    unit = _unit(landlord, status=UnitStatus.OCCUPIED)
    _unit(landlord, status=UnitStatus.VACANT)
    lease = _lease(landlord, unit)
    RentScheduleFactory(
        lease=lease, period="2026-01", amount=Decimal("10000.00"),
        status=RentScheduleStatus.PAID,
    )
    RentScheduleFactory(
        lease=lease, period="2026-02", amount=Decimal("5000.00"),
        status=RentScheduleStatus.OVERDUE,
    )

    summary = get_portfolio_summary(landlord)

    assert summary.collected == Decimal("10000.00")
    assert summary.overdue == Decimal("5000.00")
    assert summary.occupied_units == 1
    assert summary.total_units == 2
    assert summary.occupancy_rate == 50.0
    assert summary.overdue_count == 1
    assert not summary.is_empty


def test_summary_is_strictly_own_data(landlord):
    """A second landlord's data must never appear in the first's summary."""
    other = UserFactory(role=Role.LANDLORD)
    other_unit = _unit(other, status=UnitStatus.OCCUPIED)
    other_lease = _lease(other, other_unit)
    RentScheduleFactory(
        lease=other_lease, period="2026-01", amount=Decimal("99999.00"),
        status=RentScheduleStatus.PAID,
    )
    RentScheduleFactory(
        lease=other_lease, period="2026-02", amount=Decimal("12345.00"),
        status=RentScheduleStatus.OVERDUE,
    )

    summary = get_portfolio_summary(landlord)

    assert summary.collected == Decimal("0.00")
    assert summary.overdue == Decimal("0.00")
    assert summary.total_units == 0
    assert summary.overdue_count == 0
    assert summary.is_empty


def test_tool_takes_no_user_id_parameter():
    """The own-data guarantee is structural: the only argument is the user."""
    import inspect

    params = list(inspect.signature(get_portfolio_summary).parameters)
    assert params == ["user"]


def test_empty_portfolio_renders_no_block(landlord):
    summary = get_portfolio_summary(landlord)
    assert summary.is_empty
    assert format_portfolio_summary(summary) == ""


def test_anonymous_user_gets_empty_summary():
    summary = get_portfolio_summary(AnonymousUser())
    assert summary.is_empty
    assert summary.total_units == 0
    assert summary.collected == Decimal("0.00")


def test_format_includes_key_metrics():
    summary = PortfolioSummary(
        collected=Decimal("10000.00"),
        pending=Decimal("2000.00"),
        overdue=Decimal("3000.00"),
        collection_rate=66.7,
        occupied_units=2,
        total_units=4,
        occupancy_rate=50.0,
        overdue_count=1,
    )
    text = format_portfolio_summary(summary)
    assert "10000.00" in text
    assert "66.7%" in text
    assert "2 of 4" in text
    assert "Overdue tenants: 1" in text


def test_context_embeds_portfolio_summary(landlord):
    unit = _unit(landlord, status=UnitStatus.OCCUPIED)
    lease = _lease(landlord, unit)
    RentScheduleFactory(
        lease=lease, period="2026-01", amount=Decimal("7777.00"),
        status=RentScheduleStatus.PAID,
    )

    context = build_user_context(landlord)

    # Identity facts still present...
    assert "User role:" in context
    # ...plus the T-003 portfolio block. (The summed Decimal may render without
    # trailing zeros, so match on the significant digits.)
    assert "7777" in context
    assert "Occupied units:" in context


def test_context_without_portfolio_is_identity_only(landlord):
    context = build_user_context(landlord)
    assert "Rent collected" not in context
    assert "Occupied units" not in context
