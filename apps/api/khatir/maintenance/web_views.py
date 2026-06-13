"""Public, token-scoped maintenance web form (T-005).

``GET /m/<token>`` resolves a signed maintenance token (T-004) to its
:class:`~khatir.properties.models.Unit` and server-renders the ``webMaint``
screen: a no-install form where a tenant reports a maintenance issue (category,
description, optional photo) for their unit. ``POST /m/<token>`` creates a
:class:`~khatir.maintenance.models.MaintenanceRequest` (photo stored encrypted)
and redirects (PRG) to a bilingual success state. Invalid/expired tokens render
a friendly bilingual (bn default + en) error page with HTTP 404 / 410.

No login — the token alone scopes the page to exactly one unit. Server-rendered
HTML, not the Flutter app. Colours come from the Notun Din shared design tokens
(declared as CSS custom properties in the shared web base template).
"""

from __future__ import annotations

from django.core.cache import cache
from django.http import HttpRequest, HttpResponse
from django.shortcuts import redirect, render
from django.views.decorators.http import require_http_methods

from khatir.core import storage
from khatir.core.config import get_config
from khatir.leases.enums import LeaseStatus
from khatir.leases.models import Lease
from khatir.properties.models import Unit

from .enums import MaintenanceCategory
from .models import MaintenanceRequest
from .tokens import ExpiredMaintenanceToken, InvalidMaintenanceToken, resolve_token

# Per-token submit rate limit. The token already scopes the page to one unit, so
# we cap submissions per token in a window to blunt accidental double-taps and
# abusive replays — without a login or DRF throttle (this is a plain Django
# view). Tunable via SystemConfig, with a sane default pre-seed.
_SUBMIT_RATE_CONFIG_KEY = "maintenance_submit_max_per_window"
_SUBMIT_RATE_DEFAULT = 5
_SUBMIT_WINDOW_CONFIG_KEY = "maintenance_submit_window_seconds"
_SUBMIT_WINDOW_DEFAULT = 300  # 5 minutes
_SUBMIT_RATE_CACHE_PREFIX = "maintenance:submit:"

# Cap on an inline-uploaded photo (bytes). Problem photos are phone captures;
# anything larger is almost certainly abuse, so we reject early.
_MAX_PHOTO_BYTES = 8 * 1024 * 1024  # 8 MiB

# Allowed categories accepted from the posted form. The webMaint design surfaces
# water / electrical / paint / other; we map "water" to the plumbing wire value
# and accept the full enum so the form can grow without code changes.
_ALLOWED_CATEGORIES = {c.value for c in MaintenanceCategory}


def _resolve_or_error(
    request: HttpRequest, token: str
) -> tuple[Unit | None, HttpResponse | None]:
    """Resolve ``token`` → ``(unit, None)`` or ``(None, error_response)``.

    Shared by the GET form and the POST handler so the invalid (404) / expired
    (410) handling — and the "never reveal *why*" friendly error page — is
    identical across both.
    """
    try:
        return resolve_token(token), None
    except ExpiredMaintenanceToken:
        return None, render(
            request, "maintenance/web_maint_error.html", {"reason": "expired"}, status=410
        )
    except InvalidMaintenanceToken:
        return None, render(
            request, "maintenance/web_maint_error.html", {"reason": "invalid"}, status=404
        )


def _active_lease(unit: Unit) -> Lease | None:
    """Return the unit's active lease, if any, to stamp on the request."""
    return (
        Lease.objects.filter(unit=unit, status=LeaseStatus.ACTIVE)
        .order_by("-created_at")
        .first()
    )


def web_maint(request: HttpRequest, token: str) -> HttpResponse:
    """Render the token-scoped maintenance report form, or a friendly error."""
    unit, error = _resolve_or_error(request, token)
    if error is not None:
        return error
    assert unit is not None

    context = {
        "unit": unit,
        "building_name": unit.building.name,
        "unit_label": unit.label,
        "categories": list(MaintenanceCategory.choices),
        "submitted": request.GET.get("submitted") == "1",
        "token": token,
    }
    return render(request, "maintenance/web_maint.html", context)


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


def _read_category(request: HttpRequest) -> str:
    """Read + validate the posted category, defaulting to ``other``."""
    raw = (request.POST.get("category") or "").strip()
    if raw in _ALLOWED_CATEGORIES:
        return raw
    return MaintenanceCategory.OTHER


def _store_photo(request: HttpRequest) -> str:
    """Persist an optional uploaded photo encrypted; return its opaque key or "".

    Over-limit uploads are silently dropped (the request still records the
    tenant's text), matching the proof-photo handling on the rent pay page.
    """
    upload = request.FILES.get("photo")
    if upload is None or not upload.size:
        return ""
    data = upload.read(_MAX_PHOTO_BYTES + 1)
    if len(data) > _MAX_PHOTO_BYTES:
        return ""
    return storage.store_encrypted(data, kind="proof")


@require_http_methods(["POST"])
def submit_maint(request: HttpRequest, token: str) -> HttpResponse:
    """Accept a tenant's maintenance report for ``token`` and create a request.

    Creates a :class:`MaintenanceRequest` (category + description + optional
    encrypted photo), stamped with the unit's active lease if one exists.
    Rate-limited per token. On success the tenant is redirected back to the form
    in its submitted-success state (PRG). Invalid/expired tokens and an empty
    description render the same friendly surfaces as the rent pay page.
    """
    unit, error = _resolve_or_error(request, token)
    if error is not None:
        return error
    assert unit is not None

    if _rate_limited(token):
        return render(
            request, "maintenance/web_maint_error.html", {"reason": "rate_limited"}, status=429
        )

    description = (request.POST.get("description") or "").strip()
    if not description:
        # Nothing usable submitted — bounce back to the form to retry.
        return redirect("maintenance_web:web-maint", token=token)

    MaintenanceRequest.objects.create(
        unit=unit,
        lease=_active_lease(unit),
        category=_read_category(request),
        description=description,
        photo_ref=_store_photo(request),
    )

    return redirect(f"/m/{token}?submitted=1")
