"""Tests for the ``RentRequest``, ``PaymentProof`` and ``Payment`` models
(T-001 §12)."""

from __future__ import annotations

from decimal import Decimal

import pytest
from django.db import IntegrityError, models

from khatir.rent.enums import Channel, PaymentProofType, RentRequestStatus
from khatir.rent.models import Payment, PaymentProof, RentRequest

from .factories import PaymentFactory, PaymentProofFactory, RentRequestFactory

pytestmark = pytest.mark.django_db


# ---------------------------------------------------------------------------
# RentRequest
# ---------------------------------------------------------------------------


def test_rent_request_create() -> None:
    req: RentRequest = RentRequestFactory(status=RentRequestStatus.SENT)  # type: ignore[assignment]
    assert req.pk is not None
    assert req.lease_id is not None
    assert req.status == RentRequestStatus.SENT
    assert req.period == "2026-01"


def test_rent_request_default_status_is_sent() -> None:
    req: RentRequest = RentRequestFactory(status=RentRequestStatus.SENT)  # type: ignore[assignment]
    req.refresh_from_db()
    assert req.status == RentRequestStatus.SENT


def test_rent_request_default_status_db() -> None:
    """The model-level default for status is ``sent``."""
    field = RentRequest._meta.get_field("status")
    assert field.default == RentRequestStatus.SENT


def test_rent_request_amount_is_decimal() -> None:
    req: RentRequest = RentRequestFactory(amount=Decimal("18500.00"))  # type: ignore[assignment]
    req.refresh_from_db()
    assert req.amount == Decimal("18500.00")


def test_rent_request_amount_field_is_decimal_field() -> None:
    field = RentRequest._meta.get_field("amount")
    assert isinstance(field, models.DecimalField)
    assert field.max_digits == 12
    assert field.decimal_places == 2


def test_rent_request_link_token_unique() -> None:
    RentRequestFactory(link_token="dup_token")
    with pytest.raises(IntegrityError):
        RentRequestFactory(link_token="dup_token")


def test_rent_request_rent_schedule_nullable() -> None:
    req: RentRequest = RentRequestFactory(rent_schedule=None)  # type: ignore[assignment]
    req.refresh_from_db()
    assert req.rent_schedule_id is None


def test_rent_request_str() -> None:
    req: RentRequest = RentRequestFactory()  # type: ignore[assignment]
    assert f"RentRequest #{req.pk}" in str(req)
    assert f"lease {req.lease_id}" in str(req)
    assert "2026-01" in str(req)


def test_rent_request_lease_fk_is_protect() -> None:
    field = RentRequest._meta.get_field("lease")
    assert isinstance(field, models.ForeignKey)
    assert field.remote_field.on_delete is models.PROTECT


def test_rent_request_rent_schedule_fk_is_set_null() -> None:
    field = RentRequest._meta.get_field("rent_schedule")
    assert isinstance(field, models.ForeignKey)
    assert field.remote_field.on_delete is models.SET_NULL


# --- enums match enums.md ----------------------------------------------------


def test_rent_request_status_values_match_spec() -> None:
    assert set(RentRequestStatus.values) == {
        "sent",
        "proof_submitted",
        "verified",
        "rejected",
    }


def test_payment_proof_type_values_match_spec() -> None:
    assert set(PaymentProofType.values) == {
        "bkash_txn",
        "nagad_txn",
        "screenshot",
        "photo",
        "note",
    }


def test_channel_values_match_spec() -> None:
    assert set(Channel.values) == {"inapp", "whatsapp", "sms", "email"}


# --- indexes -----------------------------------------------------------------


def test_rent_request_indexes_include_link_token() -> None:
    index_field_sets = {tuple(idx.fields) for idx in RentRequest._meta.indexes}
    assert ("link_token",) in index_field_sets


def test_rent_request_indexes_include_lease_status() -> None:
    index_field_sets = {tuple(idx.fields) for idx in RentRequest._meta.indexes}
    assert ("lease", "status") in index_field_sets


# ---------------------------------------------------------------------------
# PaymentProof
# ---------------------------------------------------------------------------


def test_payment_proof_create() -> None:
    proof: PaymentProof = PaymentProofFactory()  # type: ignore[assignment]
    assert proof.pk is not None
    assert proof.rent_request_id is not None
    assert proof.type == PaymentProofType.BKASH_TXN
    assert proof.value == "TXN1234567"


def test_payment_proof_photo_ref_defaults_empty() -> None:
    proof: PaymentProof = PaymentProofFactory()  # type: ignore[assignment]
    proof.refresh_from_db()
    assert proof.photo_ref == ""


def test_payment_proof_str() -> None:
    proof: PaymentProof = PaymentProofFactory()  # type: ignore[assignment]
    assert f"PaymentProof #{proof.pk}" in str(proof)
    assert f"request {proof.rent_request_id}" in str(proof)


def test_payment_proof_rent_request_fk_is_cascade() -> None:
    field = PaymentProof._meta.get_field("rent_request")
    assert isinstance(field, models.ForeignKey)
    assert field.remote_field.on_delete is models.CASCADE


def test_payment_proof_cascade_on_request_delete() -> None:
    proof: PaymentProof = PaymentProofFactory()  # type: ignore[assignment]
    req = proof.rent_request
    proof_pk = proof.pk
    req.delete()
    assert PaymentProof.objects.filter(pk=proof_pk).count() == 0


# ---------------------------------------------------------------------------
# Payment
# ---------------------------------------------------------------------------


def test_payment_create() -> None:
    payment: Payment = PaymentFactory()  # type: ignore[assignment]
    assert payment.pk is not None
    assert payment.rent_request_id is not None
    assert payment.verified_by_id is not None


def test_payment_receipt_ref_defaults_empty() -> None:
    payment: Payment = PaymentFactory()  # type: ignore[assignment]
    payment.refresh_from_db()
    assert payment.receipt_ref == ""


def test_payment_str() -> None:
    payment: Payment = PaymentFactory()  # type: ignore[assignment]
    assert f"Payment #{payment.pk}" in str(payment)
    assert f"request {payment.rent_request_id}" in str(payment)


def test_payment_rent_request_fk_is_cascade() -> None:
    field = Payment._meta.get_field("rent_request")
    assert isinstance(field, models.ForeignKey)
    assert field.remote_field.on_delete is models.CASCADE


def test_payment_verified_by_fk_is_protect() -> None:
    field = Payment._meta.get_field("verified_by")
    assert isinstance(field, models.ForeignKey)
    assert field.remote_field.on_delete is models.PROTECT
