"""Public, token-scoped web pay page (T-005).

``GET /r/<token>`` resolves a signed link token (T-002) to its
:class:`RentRequest` and server-renders the ``webPay`` screen: amount, period,
landlord, bKash/Nagad instructions and a proof form. No login — the token alone
scopes the page to exactly one request. Invalid/expired tokens render a
friendly bilingual (bn default + en) error page with HTTP 404 / 410.

Server-rendered HTML, not the Flutter app. Colours come from the Notun Din
shared design tokens (declared as CSS custom properties in the template).
"""

from __future__ import annotations

from django.core.cache import cache
from django.http import HttpRequest, HttpResponse
from django.shortcuts import redirect, render
from django.views.decorators.http import require_http_methods

from khatir.core import storage
from khatir.core.config import get_config

from .enums import PaymentProofType, RentRequestStatus
from .models import PaymentProof, RentRequest
from .services import submit_payment_proof
from .tokens import ExpiredLinkToken, InvalidLinkToken, resolve_token

# Landlord cash-in instruction (account number) shown on the pay page. Seeded /
# tunable via SystemConfig; the default keeps the page renderable pre-seed.
_PAY_NUMBER_CONFIG_KEY = "rent_pay_instruction_number"
_PAY_NUMBER_DEFAULT = ""

# Per-token proof-submit rate limit. The token already scopes the page to one
# request, so we cap submissions per token in a window to blunt accidental
# double-taps and abusive replays — without a login or DRF throttle (this is a
# plain Django view). Tunable via SystemConfig, with a sane default pre-seed.
_PROOF_RATE_CONFIG_KEY = "rent_proof_submit_max_per_window"
_PROOF_RATE_DEFAULT = 5
_PROOF_WINDOW_CONFIG_KEY = "rent_proof_submit_window_seconds"
_PROOF_WINDOW_DEFAULT = 300  # 5 minutes
_PROOF_RATE_CACHE_PREFIX = "rent:proof_submit:"

# Cap on an inline-uploaded screenshot (bytes). Proof screenshots are phone
# captures; anything larger is almost certainly abuse, so we reject early.
_MAX_SCREENSHOT_BYTES = 8 * 1024 * 1024  # 8 MiB

# Map a request status to whether its receipt page is "ready" (verified) vs
# "pending". Only ``verified`` requests have a confirmed ``Payment``.
_VERIFIED = RentRequestStatus.VERIFIED

# English month names for the YYYY-MM period label (bn label is built from the
# Bangla numeral digits of the year).
_EN_MONTHS = (
    "",
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
)
_BN_MONTHS = (
    "",
    "জানুয়ারি",
    "ফেব্রুয়ারি",
    "মার্চ",
    "এপ্রিল",
    "মে",
    "জুন",
    "জুলাই",
    "আগস্ট",
    "সেপ্টেম্বর",
    "অক্টোবর",
    "নভেম্বর",
    "ডিসেম্বর",
)
_BN_DIGITS = str.maketrans("0123456789", "০১২৩৪৫৬৭৮৯")


def _to_bn_digits(value: str) -> str:
    return value.translate(_BN_DIGITS)


def _period_labels(period: str) -> tuple[str, str]:
    """Return ``(bn, en)`` human labels for a ``YYYY-MM`` period string."""
    try:
        year, month = period.split("-")
        m = int(month)
    except (ValueError, AttributeError):
        return period, period
    en = f"{_EN_MONTHS[m]} {year}" if 1 <= m <= 12 else period
    bn = f"{_BN_MONTHS[m]} {_to_bn_digits(year)}" if 1 <= m <= 12 else period
    return bn, en


def _amount_labels(amount: object) -> tuple[str, str]:
    """Return ``(bn, en)`` Taka labels with thousands separators."""
    whole = int(amount)  # type: ignore[call-overload]
    en = f"{whole:,}"
    bn = _to_bn_digits(en)
    return bn, en


def _resolve_or_error(
    request: HttpRequest, token: str
) -> tuple[RentRequest | None, HttpResponse | None]:
    """Resolve ``token`` → ``(rent_request, None)`` or ``(None, error_response)``.

    Shared by every token-scoped web view so the invalid (404) / expired (410)
    handling — and the "never reveal *why*" friendly error page — is identical
    across the pay page, the proof POST and the receipt page.
    """
    try:
        return resolve_token(token), None
    except ExpiredLinkToken:
        return None, render(
            request, "rent/web_pay_error.html", {"reason": "expired"}, status=410
        )
    except InvalidLinkToken:
        return None, render(
            request, "rent/web_pay_error.html", {"reason": "invalid"}, status=404
        )


def _proof_value_labels(proof: PaymentProof | None) -> tuple[str, str]:
    """Return ``(method_bn, method_en)`` describing a submitted proof, if any."""
    if proof is None:
        return "", ""
    type_label = str(PaymentProofType(proof.type).label)
    detail = proof.value or ("স্ক্রিনশট" if proof.photo_ref else "")
    en = f"{type_label} · {detail}".strip(" ·") if detail else type_label
    return en, en


def web_pay(request: HttpRequest, token: str) -> HttpResponse:
    """Render the token-scoped rent pay page, or a friendly error."""
    rent_request, error = _resolve_or_error(request, token)
    if error is not None:
        return error
    assert rent_request is not None

    lease = rent_request.lease
    amount_bn, amount_en = _amount_labels(rent_request.amount)
    period_bn, period_en = _period_labels(rent_request.period)
    pay_number = get_config(_PAY_NUMBER_CONFIG_KEY, default=_PAY_NUMBER_DEFAULT)

    context = {
        "rent_request": rent_request,
        "landlord_name": lease.landlord.name or "",
        "unit_label": lease.unit.label,
        "amount_bn": amount_bn,
        "amount_en": amount_en,
        "period_bn": period_bn,
        "period_en": period_en,
        "pay_number": pay_number,
        "token": token,
    }
    return render(request, "rent/web_pay.html", context)


def _rate_limited(token: str) -> bool:
    """Return ``True`` if this token has hit its proof-submit cap in the window.

    Counter lives in the cache backend (Redis in prod, LocMem in tests) keyed by
    the token, like every other rate-limit primitive in the project. The window
    is set on first hit so the count expires automatically.
    """
    max_per_window = int(get_config(_PROOF_RATE_CONFIG_KEY, default=_PROOF_RATE_DEFAULT))
    window = int(get_config(_PROOF_WINDOW_CONFIG_KEY, default=_PROOF_WINDOW_DEFAULT))
    key = f"{_PROOF_RATE_CACHE_PREFIX}{token}"
    # ``add`` only sets (and starts the TTL) when the key is absent, so the
    # window is anchored to the first submission and not extended by later ones.
    if cache.add(key, 1, timeout=window):
        return False
    try:
        count = cache.incr(key)
    except ValueError:
        # Key expired between ``add`` and ``incr``; treat as a fresh window.
        cache.add(key, 1, timeout=window)
        return False
    return count > max_per_window


def _build_proof(request: HttpRequest) -> tuple[str, str, str]:
    """Read the posted form → ``(type, value, photo_ref)`` for a PaymentProof.

    A screenshot upload wins (stored encrypted, returns an opaque ``photo_ref``);
    otherwise a transaction id is recorded as a ``bkash_txn``; a bare note falls
    back to a ``note``. Empty submissions yield an empty value, which the caller
    rejects.
    """
    upload = request.FILES.get("screenshot")
    if upload is not None and upload.size:
        data = upload.read(_MAX_SCREENSHOT_BYTES + 1)
        if len(data) > _MAX_SCREENSHOT_BYTES:
            return PaymentProofType.SCREENSHOT, "", ""
        photo_ref = storage.store_encrypted(data, kind="proof")
        return PaymentProofType.SCREENSHOT, "", photo_ref

    txn_id = (request.POST.get("txn_id") or "").strip()
    if txn_id:
        return PaymentProofType.BKASH_TXN, txn_id[:255], ""

    note = (request.POST.get("note") or "").strip()
    if note:
        return PaymentProofType.NOTE, note[:255], ""

    return PaymentProofType.NOTE, "", ""


@require_http_methods(["POST"])
def submit_proof(request: HttpRequest, token: str) -> HttpResponse:
    """Accept a tenant's payment proof for ``token`` and advance the request.

    Creates a :class:`PaymentProof` (txn id / encrypted screenshot / note) and,
    on first proof, moves the request to ``proof_submitted``. Rate-limited per
    token. On success the tenant is redirected to the receipt page (PRG), which
    shows the pending → ready states. Invalid/expired tokens and empty or
    over-limit submissions render the same friendly error surface.
    """
    rent_request, error = _resolve_or_error(request, token)
    if error is not None:
        return error
    assert rent_request is not None

    if _rate_limited(token):
        return render(
            request, "rent/web_pay_error.html", {"reason": "rate_limited"}, status=429
        )

    proof_type, value, photo_ref = _build_proof(request)
    if not value and not photo_ref:
        # Nothing usable submitted — bounce back to the pay page to retry.
        return redirect("rent_web:web-pay", token=token)

    # Same PaymentProof pipeline the in-app endpoint uses (EPIC-19 T-003): create
    # the proof and advance a still-pending request to ``proof_submitted``.
    submit_payment_proof(
        rent_request=rent_request,
        proof_type=proof_type,
        value=value,
        photo_ref=photo_ref,
    )

    return redirect("rent_web:web-receipt", token=token)


def web_receipt(request: HttpRequest, token: str) -> HttpResponse:
    """Render the token-scoped receipt page: pending until the landlord verifies.

    Before verification it shows the "submitted, awaiting verification" state
    plus the tenant's own submission summary. Once the request is ``verified``
    (a confirmed :class:`Payment` exists) it shows the ready receipt and, if the
    receipt PDF has been generated (T-007), a signed link to it.
    """
    rent_request, error = _resolve_or_error(request, token)
    if error is not None:
        return error
    assert rent_request is not None

    lease = rent_request.lease
    amount_bn, amount_en = _amount_labels(rent_request.amount)
    period_bn, period_en = _period_labels(rent_request.period)
    proof = rent_request.proofs.order_by("-created_at").first()
    method_bn, method_en = _proof_value_labels(proof)

    verified = rent_request.status == _VERIFIED
    receipt_url = ""
    if verified:
        payment = rent_request.payments.order_by("-created_at").first()
        if payment is not None and payment.receipt_ref:
            receipt_url = storage.signed_url(payment.receipt_ref)

    context = {
        "rent_request": rent_request,
        "landlord_name": lease.landlord.name or "",
        "unit_label": lease.unit.label,
        "amount_bn": amount_bn,
        "amount_en": amount_en,
        "period_bn": period_bn,
        "period_en": period_en,
        "method_bn": method_bn,
        "method_en": method_en,
        "submitted_at": proof.submitted_at if proof else None,
        "verified": verified,
        "receipt_url": receipt_url,
        "token": token,
    }
    return render(request, "rent/web_receipt.html", context)
