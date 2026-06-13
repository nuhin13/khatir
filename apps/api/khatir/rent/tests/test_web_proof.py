"""Tests for the token-scoped proof submit + web receipt page (T-006)."""

from __future__ import annotations

import pytest
from django.core.cache import cache
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import Client

from khatir.rent import tokens, web_views
from khatir.rent.enums import PaymentProofType, RentRequestStatus
from khatir.rent.models import PaymentProof, RentRequest
from khatir.rent.tests.factories import (
    PaymentFactory,
    PaymentProofFactory,
    RentRequestFactory,
)


@pytest.fixture(autouse=True)
def _clear_cache() -> None:
    """Each test starts with a clean rate-limit counter."""
    cache.clear()


@pytest.mark.django_db
def test_submit_proof_txn_id(client: Client) -> None:
    rr: RentRequest = RentRequestFactory(status=RentRequestStatus.SENT)  # type: ignore[assignment]
    token = tokens.make_token(rr)

    resp = client.post(f"/r/{token}/proof", {"txn_id": "8GH4K2L9PQ"})
    # Post/redirect/get → the receipt page.
    assert resp.status_code == 302
    assert resp.headers["Location"] == f"/r/{token}/receipt"

    proof = PaymentProof.objects.get(rent_request=rr)
    assert proof.type == PaymentProofType.BKASH_TXN
    assert proof.value == "8GH4K2L9PQ"
    assert proof.submitted_at is not None

    rr.refresh_from_db()
    assert rr.status == RentRequestStatus.PROOF_SUBMITTED


@pytest.mark.django_db
def test_submit_proof_screenshot_stored_encrypted(client: Client) -> None:
    rr: RentRequest = RentRequestFactory(status=RentRequestStatus.SENT)  # type: ignore[assignment]
    token = tokens.make_token(rr)
    upload = SimpleUploadedFile("shot.png", b"\x89PNG fake bytes", content_type="image/png")

    resp = client.post(f"/r/{token}/proof", {"screenshot": upload})
    assert resp.status_code == 302

    proof = PaymentProof.objects.get(rent_request=rr)
    assert proof.type == PaymentProofType.SCREENSHOT
    # Stored via encrypted storage → opaque, ``proof``-namespaced key, not raw bytes.
    assert proof.photo_ref.startswith("proof/")
    assert proof.value == ""


@pytest.mark.django_db
def test_submit_empty_bounces_to_pay(client: Client) -> None:
    rr: RentRequest = RentRequestFactory(status=RentRequestStatus.SENT)  # type: ignore[assignment]
    token = tokens.make_token(rr)

    resp = client.post(f"/r/{token}/proof", {})
    assert resp.status_code == 302
    assert resp.headers["Location"] == f"/r/{token}"
    assert not PaymentProof.objects.filter(rent_request=rr).exists()
    rr.refresh_from_db()
    assert rr.status == RentRequestStatus.SENT


@pytest.mark.django_db
def test_submit_proof_invalid_token_404(client: Client) -> None:
    resp = client.post("/r/not-a-real-token/proof", {"txn_id": "X"})
    assert resp.status_code == 404
    assert not PaymentProof.objects.exists()


@pytest.mark.django_db
def test_proof_endpoint_rejects_get(client: Client) -> None:
    rr: RentRequest = RentRequestFactory()  # type: ignore[assignment]
    token = tokens.make_token(rr)
    resp = client.get(f"/r/{token}/proof")
    assert resp.status_code == 405


@pytest.mark.django_db
def test_receipt_pending_before_verify(client: Client) -> None:
    rr: RentRequest = RentRequestFactory(  # type: ignore[assignment]
        amount="26000.00", period="2026-05", status=RentRequestStatus.PROOF_SUBMITTED
    )
    PaymentProofFactory(rent_request=rr, value="8GH4K2L9PQ")
    token = tokens.make_token(rr)

    resp = client.get(f"/r/{token}/receipt")
    assert resp.status_code == 200
    body = resp.content.decode()
    # Pending state, no download link.
    assert "Pending verification" in body
    assert "৳২৬,০০০" in body
    assert "Download receipt" not in body


@pytest.mark.django_db
def test_receipt_after_verify_shows_receipt(client: Client) -> None:
    rr: RentRequest = RentRequestFactory(  # type: ignore[assignment]
        amount="26000.00", period="2026-05", status=RentRequestStatus.VERIFIED
    )
    PaymentProofFactory(rent_request=rr, value="8GH4K2L9PQ")
    PaymentFactory(rent_request=rr, receipt_ref="pdf/abc123")
    token = tokens.make_token(rr)

    resp = client.get(f"/r/{token}/receipt")
    assert resp.status_code == 200
    body = resp.content.decode()
    assert "Payment verified" in body
    assert "Pending verification" not in body
    # Signed link to the generated receipt PDF is rendered.
    assert "Download receipt" in body
    assert "pdf/abc123" in body


@pytest.mark.django_db
def test_receipt_invalid_token_404(client: Client) -> None:
    resp = client.get("/r/not-a-real-token/receipt")
    assert resp.status_code == 404


@pytest.mark.django_db
def test_rate_limit_per_token(
    client: Client, monkeypatch: pytest.MonkeyPatch
) -> None:
    rr: RentRequest = RentRequestFactory(status=RentRequestStatus.SENT)  # type: ignore[assignment]
    token = tokens.make_token(rr)

    # Tighten the cap to make the test fast and deterministic; the window key
    # falls through to its passed-in default so the counter still expires.
    def _cfg(key: str, default: object = None) -> object:
        if key == web_views._PROOF_RATE_CONFIG_KEY:
            return 2
        return default

    monkeypatch.setattr(web_views, "get_config", _cfg)

    # First 2 submissions (the cap) succeed → redirect to receipt.
    for _ in range(2):
        resp = client.post(f"/r/{token}/proof", {"txn_id": "8GH4K2L9PQ"})
        assert resp.status_code == 302

    # The 3rd within the window is rate-limited.
    resp = client.post(f"/r/{token}/proof", {"txn_id": "8GH4K2L9PQ"})
    assert resp.status_code == 429
    assert PaymentProof.objects.filter(rent_request=rr).count() == 2
