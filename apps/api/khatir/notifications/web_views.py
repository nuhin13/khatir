"""Public, token-scoped delivery-tracking web routes — EPIC-15 T-004.

Two no-login, browser/provider-facing endpoints advance a
:class:`~khatir.notifications.models.NotificationDelivery` after it has been sent
(see :mod:`khatir.notifications.tasks`). Both are scoped solely by a signed
:mod:`~khatir.notifications.tracking` token — there is no session — so the token
itself is the capability.

* ``GET /n/<token>/open.gif`` — the **open beacon**. A 1×1 transparent GIF
  embedded in a web link / receipt page (the EPIC-07 receipt, T-004 §1). The
  first fetch marks the delivery ``opened`` (and bumps the parent
  ``opened_count``); a reload is a harmless no-op. It *always* returns the pixel,
  even for an unknown/tampered token, so it never reveals tracking state and a
  broken token still renders cleanly in the recipient's page.

* ``POST /n/<token>/delivered`` — the **provider delivery webhook**. A
  WhatsApp/SMS provider posts this once its network confirms delivery,
  advancing a ``sent`` row to ``delivered``. The signed token authenticates the
  callback (no separate shared secret to rotate); a duplicate post (providers
  retry) is idempotent.

These live at the project root (not under ``/api/v1/``) like the other
public web surfaces (rent / maintenance), because they are hit by browsers and
external providers, not the authenticated app.
"""

from __future__ import annotations

from django.http import HttpRequest, HttpResponse, JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods

from . import tasks
from .tracking import InvalidTrackingToken, resolve_token

# A 1×1 fully-transparent GIF (43 bytes). Served verbatim as the open beacon so
# the recipient's page renders a real (invisible) image regardless of tracking
# outcome.
_PIXEL_GIF = bytes(
    [
        0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00, 0x80, 0x00,
        0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0x21, 0xF9, 0x04, 0x01, 0x00,
        0x00, 0x00, 0x00, 0x2C, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00,
        0x00, 0x02, 0x02, 0x44, 0x01, 0x00, 0x3B,
    ]
)


def _pixel_response() -> HttpResponse:
    resp = HttpResponse(_PIXEL_GIF, content_type="image/gif")
    # Never let a CDN/browser cache the beacon, or a re-open would never re-hit
    # the server (the no-op guard already makes repeat hits cheap and safe).
    resp["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
    resp["Pragma"] = "no-cache"
    return resp


@require_http_methods(["GET"])
def open_beacon(request: HttpRequest, token: str) -> HttpResponse:
    """Record an open for the token's delivery, then return a 1×1 pixel.

    Always returns the pixel (HTTP 200), even for an invalid token, so the
    embedding page never shows a broken image and the endpoint leaks nothing
    about whether a token is valid.
    """
    try:
        delivery = resolve_token(token)
    except InvalidTrackingToken:
        return _pixel_response()

    tasks.mark_opened(delivery.pk)
    return _pixel_response()


@csrf_exempt
@require_http_methods(["POST"])
def delivery_webhook(request: HttpRequest, token: str) -> HttpResponse:
    """Confirm a remote-channel delivery from a provider callback.

    The signed token authenticates the callback and identifies the delivery;
    advancing a ``sent`` row to ``delivered`` is idempotent (duplicate provider
    retries are accepted with HTTP 200). An invalid/unknown token is a 404.
    """
    try:
        delivery = resolve_token(token)
    except InvalidTrackingToken:
        return JsonResponse({"detail": "Unknown delivery."}, status=404)

    confirmed = tasks.confirm_delivered(delivery.pk)
    return JsonResponse({"confirmed": confirmed}, status=200)
