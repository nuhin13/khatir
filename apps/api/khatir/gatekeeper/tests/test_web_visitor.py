"""Tests for the token-scoped visitor sign-in submit endpoint (T-004)."""

from __future__ import annotations

import pytest
from django.core.cache import cache
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import Client

from khatir.core.models import AuditEntry
from khatir.featureflags.enums import FlagScope
from khatir.featureflags.models import FeatureFlag
from khatir.gatekeeper import tokens, web_views
from khatir.gatekeeper.enums import VisitorEntryStatus
from khatir.gatekeeper.flags import GATEKEEPER_ENABLED
from khatir.gatekeeper.models import VisitorEntry
from khatir.properties.models import Building
from khatir.properties.tests.factories import BuildingFactory


@pytest.fixture(autouse=True)
def _clear_cache() -> None:
    """Each test starts with a clean rate-limit counter."""
    cache.clear()


@pytest.mark.django_db
def test_submit_creates_pending_entry(client: Client) -> None:
    building: Building = BuildingFactory()  # type: ignore[assignment]
    token = tokens.make_token(building)

    resp = client.post(
        f"/v/{token}/submit",
        {"visitor_name": "Rahim Uddin", "purpose": "Parcel delivery"},
    )
    assert resp.status_code == 302
    assert resp.headers["Location"] == f"/v/{token}?submitted=1"

    entry = VisitorEntry.objects.get(building=building)
    assert entry.visitor_name == "Rahim Uddin"
    assert entry.purpose == "Parcel delivery"
    assert entry.status == VisitorEntryStatus.PENDING
    # Visitor self-signs in; no caretaker has reviewed yet.
    assert entry.logged_by_id is None
    assert entry.get_photo_ref() is None


@pytest.mark.django_db
def test_submit_is_audited(client: Client) -> None:
    building: Building = BuildingFactory()  # type: ignore[assignment]
    token = tokens.make_token(building)

    client.post(f"/v/{token}/submit", {"visitor_name": "Karim"})

    entry = VisitorEntry.objects.get(building=building)
    audit = AuditEntry.objects.get(action="visitor.log")
    # Anonymous, no-login submission → system audit (no actor).
    assert audit.actor_id is None
    assert audit.target_type == "gatekeeper.visitorentry"
    assert audit.target_id == str(entry.pk)


@pytest.mark.django_db
def test_submit_stores_photo_encrypted(
    client: Client, monkeypatch: pytest.MonkeyPatch
) -> None:
    building: Building = BuildingFactory()  # type: ignore[assignment]
    token = tokens.make_token(building)
    upload = SimpleUploadedFile("face.png", b"\x89PNG fake bytes", content_type="image/png")

    captured: dict[str, object] = {}

    def _fake_store(data: bytes, *, kind: str) -> str:
        captured["data"] = data
        captured["kind"] = kind
        return f"{kind}/abc123"

    monkeypatch.setattr(web_views.storage, "store_encrypted", _fake_store)

    resp = client.post(
        f"/v/{token}/submit",
        {"visitor_name": "Sumaiya", "photo": upload},
    )
    assert resp.status_code == 302

    entry = VisitorEntry.objects.get(building=building)
    # Photo bytes go through the encrypted-storage helper with the ``visitor``
    # kind; the opaque key is stored encrypted on the row (no plaintext column).
    assert captured["kind"] == "visitor"
    assert captured["data"] == b"\x89PNG fake bytes"
    assert entry.photo_ref_enc is not None
    assert entry.get_photo_ref() == "visitor/abc123"


@pytest.mark.django_db
def test_submit_empty_name_bounces_to_form(client: Client) -> None:
    building: Building = BuildingFactory()  # type: ignore[assignment]
    token = tokens.make_token(building)

    resp = client.post(f"/v/{token}/submit", {"visitor_name": "   "})
    assert resp.status_code == 302
    assert resp.headers["Location"] == f"/v/{token}"
    assert not VisitorEntry.objects.filter(building=building).exists()


@pytest.mark.django_db
def test_submit_invalid_token_404(client: Client) -> None:
    resp = client.post("/v/not-a-real-token/submit", {"visitor_name": "x"})
    assert resp.status_code == 404
    assert not VisitorEntry.objects.exists()


@pytest.mark.django_db
def test_submit_expired_token_410(
    client: Client, monkeypatch: pytest.MonkeyPatch
) -> None:
    building: Building = BuildingFactory()  # type: ignore[assignment]
    token = tokens.make_token(building)
    monkeypatch.setattr(tokens, "_ttl_seconds", lambda: -1)

    resp = client.post(f"/v/{token}/submit", {"visitor_name": "x"})
    assert resp.status_code == 410
    assert not VisitorEntry.objects.exists()


@pytest.mark.django_db
def test_submit_rejects_get(client: Client) -> None:
    building: Building = BuildingFactory()  # type: ignore[assignment]
    token = tokens.make_token(building)
    resp = client.get(f"/v/{token}/submit")
    assert resp.status_code == 405


@pytest.mark.django_db
def test_submit_blocked_when_flag_disabled(client: Client) -> None:
    building: Building = BuildingFactory()  # type: ignore[assignment]
    token = tokens.make_token(building)
    FeatureFlag.objects.create(
        key=GATEKEEPER_ENABLED, scope=FlagScope.GLOBAL, enabled=False
    )

    resp = client.post(f"/v/{token}/submit", {"visitor_name": "Rahim"})
    # Feature off behaves like an unknown link — never reveal the page exists.
    assert resp.status_code == 404
    assert not VisitorEntry.objects.exists()


@pytest.mark.django_db
def test_rate_limit_per_token(
    client: Client, monkeypatch: pytest.MonkeyPatch
) -> None:
    building: Building = BuildingFactory()  # type: ignore[assignment]
    token = tokens.make_token(building)

    def _cfg(key: str, default: object = None) -> object:
        if key == web_views._SUBMIT_RATE_CONFIG_KEY:
            return 2
        return default

    monkeypatch.setattr(web_views, "get_config", _cfg)

    for _ in range(2):
        resp = client.post(f"/v/{token}/submit", {"visitor_name": "Visitor"})
        assert resp.status_code == 302

    resp = client.post(f"/v/{token}/submit", {"visitor_name": "Visitor"})
    assert resp.status_code == 429
    assert VisitorEntry.objects.filter(building=building).count() == 2
