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

from khatir.core.config import get_config
from khatir.core.enums import Area


def _area_options() -> list[str]:
    """Selectable Dhaka areas. Falls back to the ``Area`` enum if unseeded."""
    default = [choice.value for choice in Area]
    raw = get_config("area_options", default=None)
    if not raw:
        return default
    try:
        value = json.loads(raw)
    except (TypeError, ValueError):
        return default
    return value if isinstance(value, list) else default


@api_view(["GET"])
@permission_classes([AllowAny])
def healthz(request: Request) -> Response:
    """Liveness probe — no auth, no DB dependency."""
    return Response({"status": "ok"})


@api_view(["GET"])
@permission_classes([AllowAny])
def config_public(request: Request) -> Response:
    """Public client config. Surfaces unauthenticated tunables for the app."""
    return Response(
        {
            "flags": {},
            "config": {
                "intro_slide_skip_allowed": get_config(
                    "intro_slide_skip_allowed", default=True
                ),
                "area_options": _area_options(),
            },
        }
    )
