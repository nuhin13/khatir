"""Public gatekeeper web routes (EPIC-25 T-004).

``/v/<token>/submit`` is the no-login visitor sign-in POST handler, scoped by a
signed building token (T-004). It lives outside ``/api/v1/`` because it is a
browser-facing form submission, not a JSON API. Kept in its own module
(separate from ``urls.py``, which carries the ``/api/v1/`` JSON routes) so the
two URL namespaces never collide. The matching ``GET /v/<token>`` sign-in page
is added by T-005 under the same ``gatekeeper_web`` namespace.
"""

from __future__ import annotations

from django.urls import path

from .web_views import submit_visitor

app_name = "gatekeeper_web"

urlpatterns = [
    path("v/<str:token>/submit", submit_visitor, name="visitor-submit"),
]
