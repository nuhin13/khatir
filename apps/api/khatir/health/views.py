"""Health and public-config endpoints.

These are the only routes that exist before T-005 wires the core app. Both are
unauthenticated. ``config_public`` returns the public config envelope that
later epics populate with feature flags and tunable config values.
"""

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.request import Request
from rest_framework.response import Response


@api_view(["GET"])
@permission_classes([AllowAny])
def healthz(request: Request) -> Response:
    """Liveness probe — no auth, no DB dependency."""
    return Response({"status": "ok"})


@api_view(["GET"])
@permission_classes([AllowAny])
def config_public(request: Request) -> Response:
    """Public client config. Empty for now; populated by later epics."""
    return Response({"flags": {}, "config": {}})
