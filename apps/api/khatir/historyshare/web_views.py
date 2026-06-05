"""Public, token-scoped recipient web page (EPIC-24 T-008).

``GET /h/<token>`` server-renders the FACTUAL rental-history stats a tenant chose
to share with a prospective landlord. No app, no login — the opaque token is the
sole capability (a landlord can only follow a tenant-issued link, never enumerate
or originate a lookup). The page is:

* **kill-switch gated** on ``history_flags_feature`` — a killed feature renders the
  friendly error page before any lookup;
* **active + consent gated** — a missing, revoked, expired, or consent-withdrawn
  share all render the *same* 404 error page, so lifecycle state never leaks;
* **read-only + factual-only + no export** — only GET is defined and the template
  surfaces the frozen factual snapshot (counts/booleans) with no subjective field,
  no internal id and no download/print affordance.

Server-rendered HTML, not the Flutter app. Colours come from the Notun Din shared
design tokens (the ``rent/_web_base.html`` base exposes them as CSS custom
properties), so the page matches the prototype palette without hardcoding hex.
"""

from __future__ import annotations

from django.http import HttpRequest, HttpResponse
from django.shortcuts import render
from django.views.decorators.http import require_http_methods

from .flags import history_sharing_enabled
from .models import HistoryShare

# Western → Bangla digit mapping, mirroring the rent web pay page so the
# recipient sees the same localized numerals across the public web surface.
_BN_DIGITS = str.maketrans("0123456789", "০১২৩৪৫৬৭৮৯")


def _to_bn_digits(value: object) -> str:
    return str(value).translate(_BN_DIGITS)


def _error(request: HttpRequest) -> HttpResponse:
    """Render the single friendly error surface (HTTP 404).

    Every non-readable reason — unknown token, revoked, expired, consent
    withdrawn, or kill-switched — resolves here, so the page never reveals that
    a share once existed or *why* it is gone.
    """
    return render(
        request, "historyshare/web_history_error.html", {}, status=404
    )


@require_http_methods(["GET"])
def web_history(request: HttpRequest, token: str) -> HttpResponse:
    """Render the token-scoped factual rental-history page, or a friendly error."""
    if not history_sharing_enabled():
        return _error(request)

    share = (
        HistoryShare.objects.select_related("consent_record")
        .filter(token=token)
        .first()
    )
    # A missing, revoked, expired, or consent-withdrawn share all look alike:
    # the same error page so the read path never reveals lifecycle state.
    if share is None or not share.is_readable():
        return _error(request)

    stats = share.factual_stats or {}
    on_time = int(stats.get("on_time_payment_count", 0) or 0)
    total = int(stats.get("total_payments", 0) or 0)
    lease_completed = bool(stats.get("lease_completed", False))

    expires_label = ""
    if share.expires_at is not None:
        # Date only — the precise time is not load-bearing for the recipient.
        expires_label = _to_bn_digits(share.expires_at.strftime("%Y-%m-%d"))

    context = {
        "on_time_bn": _to_bn_digits(on_time),
        "on_time_en": str(on_time),
        "total_bn": _to_bn_digits(total),
        "total_en": str(total),
        "lease_completed": lease_completed,
        "expires_label": expires_label,
    }
    return render(request, "historyshare/web_history.html", context)
