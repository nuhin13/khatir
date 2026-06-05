"""Public gatekeeper web routes (EPIC-25 T-004).

``GET /v/<token>`` server-renders the no-login visitor sign-in *page* (T-005) and
``POST /v/<token>/submit`` is the matching submit handler (T-004), both scoped by
a signed building token. They live outside ``/api/v1/`` because they are
browser-facing, not a JSON API. Kept in their own module (separate from
``urls.py``, which carries the ``/api/v1/`` JSON routes) so the two URL
namespaces never collide.
"""

from __future__ import annotations

from django.urls import path

from .web_views import submit_visitor, web_visitor

app_name = "gatekeeper_web"

urlpatterns = [
    path("v/<str:token>", web_visitor, name="visitor-page"),
    path("v/<str:token>/submit", submit_visitor, name="visitor-submit"),
]
