"""Tests for the recipient view endpoint (EPIC-24.T-003 §12).

Exercises ``GET /api/v1/history-shares/{token}`` — the recipient landlord reads
the FACTUAL stats ONLY while the share is active and consent is valid:

* an active share is readable via its opaque token and returns factual stats;
* the response is factual-only — no subjective field, and no internal/consent
  ids that would aid enumeration or a landlord-initiated lookup;
* a revoked, expired, or consent-withdrawn share is indistinguishable from a
  non-existent one (404) — lifecycle state never leaks;
* the ``history_flags_feature`` kill-switch gates the read;
* it is read-only — POST/PUT/DELETE are not allowed (no export path).
"""

from __future__ import annotations

import datetime

import pytest
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APIClient

from khatir.compliance.tests.factories import ConsentRecordFactory
from khatir.featureflags.enums import FlagScope
from khatir.featureflags.models import FeatureFlag
from khatir.historyshare.flags import HISTORY_FLAGS_FEATURE
from khatir.historyshare.models import HistoryShare
from khatir.historyshare.tests.factories import HistoryShareFactory

pytestmark = pytest.mark.django_db


def _url(token: str) -> str:
    return f"/api/v1/history-shares/{token}"


def _set_kill_switch(*, enabled: bool) -> None:
    FeatureFlag.objects.update_or_create(
        key=HISTORY_FLAGS_FEATURE,
        defaults={"scope": FlagScope.GLOBAL, "enabled": enabled},
    )


@pytest.fixture
def client() -> APIClient:
    return APIClient()


# --- happy path --------------------------------------------------------------


def test_active_share_is_readable_by_token(client: APIClient) -> None:
    share: HistoryShare = HistoryShareFactory(  # type: ignore[assignment]
        factual_stats={
            "on_time_payment_count": 11,
            "total_payments": 12,
            "lease_completed": True,
        }
    )
    resp = client.get(_url(share.token))

    assert resp.status_code == status.HTTP_200_OK
    body = resp.json()
    assert body["token"] == share.token
    assert body["factual_stats"] == {
        "on_time_payment_count": 11,
        "total_payments": 12,
        "lease_completed": True,
    }


def test_response_is_factual_only_no_subjective_or_internal_ids(
    client: APIClient,
) -> None:
    share: HistoryShare = HistoryShareFactory(  # type: ignore[assignment]
        factual_stats={
            "on_time_payment_count": 3,
            "total_payments": 3,
            "lease_completed": False,
        }
    )
    body = client.get(_url(share.token)).json()

    # No subjective field leaks anywhere.
    forbidden = {"rating", "score", "opinion", "review", "comment", "stars"}
    assert set(body).isdisjoint(forbidden)
    assert set(body["factual_stats"]).isdisjoint(forbidden)
    # No internal/owner ids that would aid enumeration or a landlord lookup.
    leaky = {"id", "tenant", "recipient_landlord", "consent_record", "revoked_at"}
    assert set(body).isdisjoint(leaky)


# --- guards: active + consent gate -------------------------------------------


def test_revoked_share_is_404(client: APIClient) -> None:
    share: HistoryShare = HistoryShareFactory(  # type: ignore[assignment]
        revoked_at=timezone.now()
    )
    resp = client.get(_url(share.token))
    assert resp.status_code == status.HTTP_404_NOT_FOUND


def test_expired_share_is_404(client: APIClient) -> None:
    past = timezone.now() - datetime.timedelta(days=1)
    share: HistoryShare = HistoryShareFactory(expires_at=past)  # type: ignore[assignment]
    resp = client.get(_url(share.token))
    assert resp.status_code == status.HTTP_404_NOT_FOUND


def test_withdrawn_consent_share_is_404(client: APIClient) -> None:
    consent = ConsentRecordFactory(revoked_at=timezone.now())
    share: HistoryShare = HistoryShareFactory(  # type: ignore[assignment]
        consent_record=consent
    )
    resp = client.get(_url(share.token))
    assert resp.status_code == status.HTTP_404_NOT_FOUND


def test_expired_consent_share_is_404(client: APIClient) -> None:
    consent = ConsentRecordFactory(
        expires_at=timezone.now() - datetime.timedelta(hours=1)
    )
    share: HistoryShare = HistoryShareFactory(  # type: ignore[assignment]
        consent_record=consent
    )
    resp = client.get(_url(share.token))
    assert resp.status_code == status.HTTP_404_NOT_FOUND


def test_unknown_token_is_404(client: APIClient) -> None:
    resp = client.get(_url("does-not-exist"))
    assert resp.status_code == status.HTTP_404_NOT_FOUND


# --- kill switch -------------------------------------------------------------


def test_kill_switch_blocks_read(client: APIClient) -> None:
    share: HistoryShare = HistoryShareFactory()  # type: ignore[assignment]
    _set_kill_switch(enabled=False)
    resp = client.get(_url(share.token))
    assert resp.status_code == status.HTTP_403_FORBIDDEN
    assert resp.json()["error"]["code"] == "feature_disabled"


# --- read-only: no export / mutation ----------------------------------------


def test_read_only_no_mutation(client: APIClient) -> None:
    share: HistoryShare = HistoryShareFactory()  # type: ignore[assignment]
    for method in (client.post, client.put, client.patch, client.delete):
        resp = method(_url(share.token))
        assert resp.status_code == status.HTTP_405_METHOD_NOT_ALLOWED
