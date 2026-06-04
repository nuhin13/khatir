"""Public maintenance web routes (EPIC-08 T-005).

``/m/<token>`` is the no-login tenant maintenance report form. It lives outside
``/api/v1/`` because it is a browser-facing HTML page, not a JSON API. Kept in
its own module (separate from ``urls.py``, which carries the ``/api/v1/`` JSON
routes) so the two URL namespaces never collide.
"""

from __future__ import annotations

from django.urls import path

from .web_views import submit_maint, web_maint

app_name = "maintenance_web"

urlpatterns = [
    path("m/<str:token>", web_maint, name="web-maint"),
    path("m/<str:token>/submit", submit_maint, name="web-submit"),
]
