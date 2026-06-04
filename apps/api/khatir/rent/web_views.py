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

from django.http import HttpRequest, HttpResponse
from django.shortcuts import render

from khatir.core.config import get_config

from .models import RentRequest
from .tokens import ExpiredLinkToken, InvalidLinkToken, resolve_token

# Landlord cash-in instruction (account number) shown on the pay page. Seeded /
# tunable via SystemConfig; the default keeps the page renderable pre-seed.
_PAY_NUMBER_CONFIG_KEY = "rent_pay_instruction_number"
_PAY_NUMBER_DEFAULT = ""

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


def web_pay(request: HttpRequest, token: str) -> HttpResponse:
    """Render the token-scoped rent pay page, or a friendly error."""
    try:
        rent_request: RentRequest = resolve_token(token)
    except ExpiredLinkToken:
        return render(
            request,
            "rent/web_pay_error.html",
            {"reason": "expired"},
            status=410,
        )
    except InvalidLinkToken:
        return render(
            request,
            "rent/web_pay_error.html",
            {"reason": "invalid"},
            status=404,
        )

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
