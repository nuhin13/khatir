"""Tests for the token-scoped maintenance web form (T-005)."""

from __future__ import annotations

import pytest
from django.core.cache import cache
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import Client

from khatir.leases.enums import LeaseStatus
from khatir.leases.tests.factories import LeaseFactory
from khatir.maintenance import tokens, web_views
from khatir.maintenance.enums import MaintenanceCategory, MaintenanceStatus
from khatir.maintenance.models import MaintenanceRequest
from khatir.properties.models import Unit
from khatir.properties.tests.factories import UnitFactory


@pytest.fixture(autouse=True)
def _clear_cache() -> None:
    """Each test starts with a clean rate-limit counter."""
    cache.clear()


@pytest.mark.django_db
def test_form_renders(client: Client) -> None:
    unit: Unit = UnitFactory(label="4B")  # type: ignore[assignment]
    unit.building.name = "Karim Manzil"
    unit.building.save()
    token = tokens.make_token(unit)

    resp = client.get(f"/m/{token}")
    assert resp.status_code == 200

    body = resp.content.decode()
    # Building + unit context present, form server-rendered with the fields.
    assert "Karim Manzil" in body
    assert "4B" in body
    assert "<form" in body
    assert 'name="description"' in body
    assert 'name="category"' in body
    # Categories from the enum are rendered.
    assert "plumbing" in body


@pytest.mark.django_db
def test_submit_creates_request(client: Client) -> None:
    unit: Unit = UnitFactory()  # type: ignore[assignment]
    token = tokens.make_token(unit)

    resp = client.post(
        f"/m/{token}/submit",
        {"category": MaintenanceCategory.ELECTRICAL, "description": "No power in kitchen"},
    )
    # Post/redirect/get → the form's submitted-success state.
    assert resp.status_code == 302
    assert resp.headers["Location"] == f"/m/{token}?submitted=1"

    req = MaintenanceRequest.objects.get(unit=unit)
    assert req.category == MaintenanceCategory.ELECTRICAL
    assert req.description == "No power in kitchen"
    assert req.status == MaintenanceStatus.OPEN
    assert req.photo_ref == ""

    # The success state is rendered on the follow-up GET.
    success = client.get(f"/m/{token}?submitted=1")
    assert success.status_code == 200
    assert "পাঠানো হয়েছে" in success.content.decode()


@pytest.mark.django_db
def test_submit_stamps_active_lease(client: Client) -> None:
    unit: Unit = UnitFactory()  # type: ignore[assignment]
    lease = LeaseFactory(unit=unit, status=LeaseStatus.ACTIVE)
    token = tokens.make_token(unit)

    resp = client.post(f"/m/{token}/submit", {"description": "Leaking tap"})
    assert resp.status_code == 302

    req = MaintenanceRequest.objects.get(unit=unit)
    assert req.lease_id == lease.pk
    # No explicit category posted → defaults to other.
    assert req.category == MaintenanceCategory.OTHER


@pytest.mark.django_db
def test_submit_photo_stored_encrypted(
    client: Client, monkeypatch: pytest.MonkeyPatch
) -> None:
    unit: Unit = UnitFactory()  # type: ignore[assignment]
    token = tokens.make_token(unit)
    upload = SimpleUploadedFile("shot.png", b"\x89PNG fake bytes", content_type="image/png")

    # The photo must go through the encrypted-storage helper with the ``proof``
    # kind; we stub the backend so the assertion does not depend on whether the
    # environment points at S3 or the local FS fallback.
    captured: dict[str, object] = {}

    def _fake_store(data: bytes, *, kind: str) -> str:
        captured["data"] = data
        captured["kind"] = kind
        return f"{kind}/abc123"

    monkeypatch.setattr(web_views.storage, "store_encrypted", _fake_store)

    resp = client.post(
        f"/m/{token}/submit", {"description": "Broken window", "photo": upload}
    )
    assert resp.status_code == 302

    req = MaintenanceRequest.objects.get(unit=unit)
    # Stored via encrypted storage → opaque, ``proof``-namespaced key.
    assert req.photo_ref == "proof/abc123"
    assert captured["kind"] == "proof"
    assert captured["data"] == b"\x89PNG fake bytes"


@pytest.mark.django_db
def test_submit_empty_bounces_to_form(client: Client) -> None:
    unit: Unit = UnitFactory()  # type: ignore[assignment]
    token = tokens.make_token(unit)

    resp = client.post(f"/m/{token}/submit", {"description": "   "})
    assert resp.status_code == 302
    assert resp.headers["Location"] == f"/m/{token}"
    assert not MaintenanceRequest.objects.filter(unit=unit).exists()


@pytest.mark.django_db
def test_expired_token_shows_error(
    client: Client, monkeypatch: pytest.MonkeyPatch
) -> None:
    unit: Unit = UnitFactory()  # type: ignore[assignment]
    token = tokens.make_token(unit)
    monkeypatch.setattr(tokens, "_ttl_seconds", lambda: -1)

    resp = client.get(f"/m/{token}")
    assert resp.status_code == 410
    assert "মেয়াদ শেষ" in resp.content.decode()


@pytest.mark.django_db
def test_invalid_token_shows_error(client: Client) -> None:
    resp = client.get("/m/not-a-real-token")
    assert resp.status_code == 404
    assert "খুঁজে পাওয়া যায়নি" in resp.content.decode()


@pytest.mark.django_db
def test_submit_invalid_token_404(client: Client) -> None:
    resp = client.post("/m/not-a-real-token/submit", {"description": "x"})
    assert resp.status_code == 404
    assert not MaintenanceRequest.objects.exists()


@pytest.mark.django_db
def test_submit_endpoint_rejects_get(client: Client) -> None:
    unit: Unit = UnitFactory()  # type: ignore[assignment]
    token = tokens.make_token(unit)
    resp = client.get(f"/m/{token}/submit")
    assert resp.status_code == 405


@pytest.mark.django_db
def test_page_uses_token_palette_not_hardcoded(client: Client) -> None:
    unit: Unit = UnitFactory()  # type: ignore[assignment]
    token = tokens.make_token(unit)
    resp = client.get(f"/m/{token}")
    body = resp.content.decode()
    # Notun Din palette is exposed as CSS custom properties and consumed via
    # var(...) — colours are token-sourced, not scattered prototype hex.
    assert "--sage-bg" in body
    assert "var(--sage-dk)" in body


@pytest.mark.django_db
def test_rate_limit_per_token(
    client: Client, monkeypatch: pytest.MonkeyPatch
) -> None:
    unit: Unit = UnitFactory()  # type: ignore[assignment]
    token = tokens.make_token(unit)

    def _cfg(key: str, default: object = None) -> object:
        if key == web_views._SUBMIT_RATE_CONFIG_KEY:
            return 2
        return default

    monkeypatch.setattr(web_views, "get_config", _cfg)

    # First 2 submissions (the cap) succeed → redirect.
    for _ in range(2):
        resp = client.post(f"/m/{token}/submit", {"description": "issue"})
        assert resp.status_code == 302

    # The 3rd within the window is rate-limited.
    resp = client.post(f"/m/{token}/submit", {"description": "issue"})
    assert resp.status_code == 429
    assert MaintenanceRequest.objects.filter(unit=unit).count() == 2
