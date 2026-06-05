"""Tests for the recipient web page (EPIC-24 T-008).

Exercises ``GET /h/<token>`` — the server-rendered, no-login page where a
prospective landlord views the FACTUAL stats a tenant shared:

* an active share renders the factual snapshot (counts/booleans only);
* the page is factual-only — no subjective field and no internal/owner id leaks;
* a revoked, expired, consent-withdrawn or unknown share all render the SAME
  friendly 404 error page — lifecycle state never leaks;
* the ``history_flags_feature`` kill-switch renders the error page;
* it is read-only — only GET is defined (POST/PUT/DELETE → 405), no export;
* colours come from the Notun Din design tokens (CSS custom properties), not
  scattered prototype hex.
"""

from __future__ import annotations

import datetime

import pytest
from django.test import Client
from django.utils import timezone

from khatir.compliance.tests.factories import ConsentRecordFactory
from khatir.featureflags.enums import FlagScope
from khatir.featureflags.models import FeatureFlag
from khatir.historyshare.flags import HISTORY_FLAGS_FEATURE
from khatir.historyshare.models import HistoryShare
from khatir.historyshare.tests.factories import HistoryShareFactory

pytestmark = pytest.mark.django_db


def _url(token: str) -> str:
    return f"/h/{token}"


def _set_kill_switch(*, enabled: bool) -> None:
    FeatureFlag.objects.update_or_create(
        key=HISTORY_FLAGS_FEATURE,
        defaults={"scope": FlagScope.GLOBAL, "enabled": enabled},
    )


# --- happy path --------------------------------------------------------------


def test_active_share_renders_factual_stats(client: Client) -> None:
    share: HistoryShare = HistoryShareFactory(  # type: ignore[assignment]
        factual_stats={
            "on_time_payment_count": 11,
            "total_payments": 12,
            "lease_completed": True,
        }
    )
    resp = client.get(_url(share.token))

    assert resp.status_code == 200
    body = resp.content.decode()
    # Counts rendered in Bangla numerals (11 -> ১১, 12 -> ১২).
    assert "১১" in body
    assert "১২" in body
    # A completed lease term is surfaced.
    assert "Completed a full lease term" in body


def test_page_is_factual_only_no_subjective_field(client: Client) -> None:
    share: HistoryShare = HistoryShareFactory(  # type: ignore[assignment]
        factual_stats={
            "on_time_payment_count": 3,
            "total_payments": 3,
            "lease_completed": False,
        }
    )
    body = client.get(_url(share.token)).content.decode().lower()
    # No subjective notion leaks into the rendered page.
    for word in ("rating", "score", "opinion", "review", "stars"):
        assert word not in body


def test_page_has_no_export_or_form(client: Client) -> None:
    share: HistoryShare = HistoryShareFactory()  # type: ignore[assignment]
    body = client.get(_url(share.token)).content.decode().lower()
    # Read-only surface: no form, no download/export affordance.
    assert "<form" not in body
    assert "download" not in body
    assert "export" not in body


# --- guards: active + consent gate, all → identical error page ---------------


def test_revoked_share_shows_error(client: Client) -> None:
    share: HistoryShare = HistoryShareFactory(  # type: ignore[assignment]
        revoked_at=timezone.now()
    )
    resp = client.get(_url(share.token))
    assert resp.status_code == 404
    assert "not available" in resp.content.decode().lower()


def test_expired_share_shows_error(client: Client) -> None:
    past = timezone.now() - datetime.timedelta(days=1)
    share: HistoryShare = HistoryShareFactory(expires_at=past)  # type: ignore[assignment]
    resp = client.get(_url(share.token))
    assert resp.status_code == 404


def test_withdrawn_consent_share_shows_error(client: Client) -> None:
    consent = ConsentRecordFactory(revoked_at=timezone.now())
    share: HistoryShare = HistoryShareFactory(  # type: ignore[assignment]
        consent_record=consent
    )
    resp = client.get(_url(share.token))
    assert resp.status_code == 404


def test_unknown_token_shows_error(client: Client) -> None:
    resp = client.get(_url("does-not-exist"))
    assert resp.status_code == 404
    assert "not available" in resp.content.decode().lower()


# --- kill switch -------------------------------------------------------------


def test_kill_switch_shows_error(client: Client) -> None:
    share: HistoryShare = HistoryShareFactory()  # type: ignore[assignment]
    _set_kill_switch(enabled=False)
    resp = client.get(_url(share.token))
    assert resp.status_code == 404


# --- read-only: no mutation / export ----------------------------------------


def test_read_only_no_mutation(client: Client) -> None:
    share: HistoryShare = HistoryShareFactory()  # type: ignore[assignment]
    for method in (client.post, client.put, client.patch, client.delete):
        resp = method(_url(share.token))
        assert resp.status_code == 405


# --- palette is token-sourced ------------------------------------------------


def test_page_uses_token_palette_not_hardcoded(client: Client) -> None:
    share: HistoryShare = HistoryShareFactory()  # type: ignore[assignment]
    body = client.get(_url(share.token)).content.decode()
    # Notun Din palette exposed as CSS custom properties + consumed via var(...).
    assert "--sage-dk" in body
    assert "var(--sage-dk)" in body
