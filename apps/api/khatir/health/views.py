"""Health and public-config endpoints.

These are the only routes that exist before T-005 wires the core app. Both are
unauthenticated. ``config_public`` returns the public config envelope that
later epics populate with feature flags and tunable config values.
"""

import json

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.request import Request
from rest_framework.response import Response

from khatir.billing.public_config import serialized_tiers, subscription_block
from khatir.core.config import get_config
from khatir.core.enums import Area
from khatir.featureflags.services import public_flags
from khatir.maintenance.enums import ExpenseCategory, MaintenanceCategory


def _json_list_config(key: str, default: list[str]) -> list[str]:
    """Return a JSON-array ``SystemConfig`` value, falling back to ``default``."""
    raw = get_config(key, default=None)
    if not raw:
        return default
    try:
        value = json.loads(raw)
    except (TypeError, ValueError):
        return default
    return value if isinstance(value, list) else default


def _area_options() -> list[str]:
    """Selectable Dhaka areas. Falls back to the ``Area`` enum if unseeded."""
    return _json_list_config("area_options", [choice.value for choice in Area])


def _maintenance_categories() -> list[str]:
    """Selectable maintenance categories. Falls back to the enum if unseeded."""
    return _json_list_config(
        "maintenance_categories", [choice.value for choice in MaintenanceCategory]
    )


def _expense_categories() -> list[str]:
    """Selectable expense categories. Falls back to the enum if unseeded."""
    return _json_list_config(
        "expense_categories", [choice.value for choice in ExpenseCategory]
    )


@api_view(["GET"])
@permission_classes([AllowAny])
def healthz(request: Request) -> Response:
    """Liveness probe — no auth, no DB dependency."""
    return Response({"status": "ok"})


@api_view(["GET"])
@permission_classes([AllowAny])
def config_public(request: Request) -> Response:
    """Public client config. Surfaces unauthenticated tunables for the app.

    Always carries the active pricing tiers (``pricing.tiers``) so the marketing
    / plan picker can render without auth. An authenticated caller also gets a
    ``subscription`` block (current plan, status, tenant usage vs. limit, and
    whether their tier permits NID verification) so the app can enforce limits
    client-side (EPIC-10 T-005 §2). No prices/dates/payment data are exposed.
    """
    payload: dict[str, object] = {
        "flags": public_flags(),
        "config": {
            "intro_slide_skip_allowed": get_config(
                "intro_slide_skip_allowed", default=True
            ),
            "area_options": _area_options(),
            "maintenance_categories": _maintenance_categories(),
            "expense_categories": _expense_categories(),
        },
        "pricing": {"tiers": serialized_tiers()},
    }
    if request.user.is_authenticated:
        payload["subscription"] = subscription_block(request.user)
    return Response(payload)
