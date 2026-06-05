"""Public, token-scoped visitor sign-in submit endpoint (EPIC-25 T-004).

``POST /v/<token>`` resolves a signed, building-scoped visitor link token
(:mod:`khatir.gatekeeper.tokens`) and creates a **pending**
:class:`~khatir.gatekeeper.models.VisitorEntry` for that building: the visitor's
name, purpose and an optional photo (stored **encrypted at rest** as an opaque
object-storage pointer — never a plaintext column). No login — the token alone
scopes the submission to exactly one building. The write is audited
(``visitor.log``) and rate-limited per token.

The server-rendered sign-in *page* itself (``GET /v/<token>``) and its bilingual
templates are owned by T-005; this task provides only the token service and the
submit handler. The whole gatekeeper feature is behind the ``gatekeeper_enabled``
flag — when off, even the public submit returns a 404 (we never reveal the page
exists). On success the visitor is redirected (PRG) to ``/v/<token>?submitted=1``;
invalid/expired tokens and over-limit submissions return 404 / 410 / 429.
"""

from __future__ import annotations

from django.core.cache import cache
from django.http import HttpRequest, HttpResponse, HttpResponseRedirect
from django.views.decorators.http import require_http_methods

from khatir.core import storage
from khatir.core.config import get_config
from khatir.properties.models import Building

from .flags import is_gatekeeper_enabled
from .services import log_visitor_entry
from .tokens import ExpiredVisitorToken, InvalidVisitorToken, resolve_token

# Per-token submit rate limit. The token already scopes the page to one
# building, so we cap submissions per token in a window to blunt accidental
# double-taps and abusive replays — without a login or DRF throttle (this is a
# plain Django view). Tunable via SystemConfig, with a sane default pre-seed.
_SUBMIT_RATE_CONFIG_KEY = "visitor_submit_max_per_window"
_SUBMIT_RATE_DEFAULT = 10
_SUBMIT_WINDOW_CONFIG_KEY = "visitor_submit_window_seconds"
_SUBMIT_WINDOW_DEFAULT = 300  # 5 minutes
_SUBMIT_RATE_CACHE_PREFIX = "gatekeeper:visitor_submit:"

# Cap on an inline-uploaded visitor photo (bytes). Gate photos are phone/webcam
# captures; anything larger is almost certainly abuse, so we reject early.
_MAX_PHOTO_BYTES = 8 * 1024 * 1024  # 8 MiB


def _resolve_or_error(token: str) -> tuple[Building | None, HttpResponse | None]:
    """Resolve ``token`` → ``(building, None)`` or ``(None, error_response)``.

    Mirrors the rent/maintenance web flows: an expired token is 410, anything
    malformed/tampered/unknown is 404, and the response body never reveals *why*
    a link failed. T-005 swaps these bare responses for the bilingual error page.
    """
    try:
        return resolve_token(token), None
    except ExpiredVisitorToken:
        return None, HttpResponse("This visitor link has expired.", status=410)
    except InvalidVisitorToken:
        return None, HttpResponse("This visitor link is invalid.", status=404)


def _rate_limited(token: str) -> bool:
    """Return ``True`` if this token has hit its submit cap in the window.

    Counter lives in the cache backend (Redis in prod, LocMem in tests) keyed by
    the token, like every other rate-limit primitive in the project. The window
    is set on first hit so the count expires automatically.
    """
    max_per_window = int(get_config(_SUBMIT_RATE_CONFIG_KEY, default=_SUBMIT_RATE_DEFAULT))
    window = int(get_config(_SUBMIT_WINDOW_CONFIG_KEY, default=_SUBMIT_WINDOW_DEFAULT))
    key = f"{_SUBMIT_RATE_CACHE_PREFIX}{token}"
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


def _store_photo(request: HttpRequest) -> str | None:
    """Persist an optional uploaded photo encrypted; return its opaque key or None.

    Over-limit uploads are silently dropped (the entry still records the
    visitor's name + purpose), matching the proof/maintenance photo handling.
    The returned key is what gets stored encrypted on the entry via
    ``set_photo_ref`` — the photo bytes themselves are encrypted at rest by the
    storage backend, and the pointer to them is encrypted on the row.
    """
    upload = request.FILES.get("photo")
    if upload is None or not upload.size:
        return None
    data = upload.read(_MAX_PHOTO_BYTES + 1)
    if len(data) > _MAX_PHOTO_BYTES:
        return None
    return storage.store_encrypted(data, kind="visitor")


@require_http_methods(["POST"])
def submit_visitor(request: HttpRequest, token: str) -> HttpResponse:
    """Accept a visitor sign-in for ``token`` and create a pending entry.

    Resolves the building-scoped token, enforces the ``gatekeeper_enabled`` flag
    (a disabled feature 404s — we never reveal the page exists), rate-limits per
    token, then creates a ``pending`` :class:`VisitorEntry` with the visitor's
    name, purpose and optional encrypted photo. On success the visitor is
    redirected (PRG) to the sign-in page's submitted-success state.
    """
    if not is_gatekeeper_enabled():
        # Feature off: behave exactly like an unknown link (never reveal it).
        return HttpResponse("This visitor link is invalid.", status=404)

    building, error = _resolve_or_error(token)
    if error is not None:
        return error
    assert building is not None

    if _rate_limited(token):
        return HttpResponse("Too many submissions. Please wait.", status=429)

    visitor_name = (request.POST.get("visitor_name") or "").strip()
    if not visitor_name:
        # Nothing usable submitted — bounce back to the form to retry.
        return HttpResponseRedirect(f"/v/{token}")
    purpose = (request.POST.get("purpose") or "").strip()[:255]

    log_visitor_entry(
        building=building,
        visitor_name=visitor_name[:120],
        purpose=purpose,
        photo_ref=_store_photo(request),
    )

    return HttpResponseRedirect(f"/v/{token}?submitted=1")
