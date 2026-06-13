"""Tests for the warning-notice PDF endpoint (T-003 §12).

Covers: notice generation (200/201, ``notice_ref`` persisted, signed URL
returned, audited), that the rendered PDF carries the parties / type / reason /
date / disclaimer, the ``warnings_feature`` kill-switch (403 when off, nothing
generated), and that a foreign warning is invisible (404 — never a
cross-landlord read).
"""

from __future__ import annotations

import pytest
from rest_framework import status
from rest_framework.test import APIClient

from khatir.accounts.enums import Role
from khatir.accounts.models import User
from khatir.accounts.tests.factories import UserFactory
from khatir.core.models import AuditEntry
from khatir.featureflags.enums import FlagScope
from khatir.featureflags.tests.factories import FeatureFlagFactory
from khatir.leases.tests.factories import LeaseFactory
from khatir.warnings.enums import WarningType
from khatir.warnings.models import Warning
from khatir.warnings.notice import DISCLAIMER, render_notice_pdf

pytestmark = pytest.mark.django_db


def _path(warning_id: int) -> str:
    return f"/api/v1/warnings/{warning_id}/notice"


@pytest.fixture
def landlord() -> User:
    created: User = UserFactory(  # type: ignore[assignment]
        phone="+8801712345678", name="Landlord A", role=Role.LANDLORD
    )
    return created


@pytest.fixture
def client(landlord: User) -> APIClient:
    api = APIClient()
    api.force_authenticate(user=landlord)
    return api


def _make_warning(landlord: User, **kwargs: object) -> Warning:
    lease = LeaseFactory(landlord=landlord)
    return Warning.objects.create(
        lease=lease,
        tenant_id=lease.tenant_id,
        landlord=landlord,
        warning_type=kwargs.get("warning_type", WarningType.LATE_RENT),
        reason=kwargs.get("reason", "Rent overdue 14 days"),
    )


def test_notice_pdf_generated(client: APIClient, landlord: User) -> None:
    """POST generates the notice, persists notice_ref, returns a signed URL."""
    warning = _make_warning(landlord)
    assert warning.notice_ref == ""

    resp = client.post(_path(warning.pk))
    assert resp.status_code == status.HTTP_201_CREATED
    body = resp.json()
    assert body["notice_ref"]
    assert body["notice_url"]

    warning.refresh_from_db()
    assert warning.notice_ref == body["notice_ref"]
    # The generation is audited.
    assert AuditEntry.objects.filter(
        action="warning.notice", target_id=str(warning.pk)
    ).exists()


def test_notice_pdf_contains_fields_and_disclaimer(landlord: User) -> None:
    """The rendered PDF carries parties, type, reason, date and the disclaimer."""
    warning = _make_warning(
        landlord, reason="Loud music after midnight", warning_type=WarningType.NOISE
    )
    pdf = render_notice_pdf(warning)
    assert pdf.startswith(b"%PDF-")
    text = pdf.decode("latin-1")
    assert "Landlord A" in text  # landlord party
    assert warning.tenant.name in text  # tenant party
    assert WarningType.NOISE.label in text  # warning type
    assert "Loud music after midnight" in text  # reason
    assert warning.issued_at.isoformat() in text  # issue date
    assert DISCLAIMER in text  # mandatory legal disclaimer (§15)


def test_notice_killswitch_off(client: APIClient, landlord: User) -> None:
    """When ``warnings_feature`` is off, the notice endpoint returns 403."""
    FeatureFlagFactory(key="warnings_feature", scope=FlagScope.GLOBAL, enabled=False)
    warning = _make_warning(landlord)

    resp = client.post(_path(warning.pk))
    assert resp.status_code == status.HTTP_403_FORBIDDEN
    assert resp.json()["error"]["code"] == "feature_disabled"

    warning.refresh_from_db()
    assert warning.notice_ref == ""  # nothing generated


def test_notice_cross_landlord_404(client: APIClient, landlord: User) -> None:
    """A foreign warning is invisible — resolves to 404, never a leak."""
    other = UserFactory(phone="+8801733333333", role=Role.LANDLORD)
    foreign_lease = LeaseFactory(landlord=other)
    foreign = Warning.objects.create(
        lease=foreign_lease,
        tenant_id=foreign_lease.tenant_id,
        landlord=other,
        reason="Other landlord's warning",
    )

    resp = client.post(_path(foreign.pk))
    assert resp.status_code == status.HTTP_404_NOT_FOUND
    foreign.refresh_from_db()
    assert foreign.notice_ref == ""  # untouched


def test_notice_requires_auth(landlord: User) -> None:
    warning = _make_warning(landlord)
    resp = APIClient().post(_path(warning.pk))
    assert resp.status_code in (
        status.HTTP_401_UNAUTHORIZED,
        status.HTTP_403_FORBIDDEN,
    )
