"""Public history-share web routes (EPIC-24 T-008).

``/h/<token>`` is the no-login recipient page where a prospective landlord views
the FACTUAL stats a tenant shared. It lives outside ``/api/v1/`` because it is a
browser-facing HTML page, not a JSON API — kept in its own module (separate from
``urls.py``, which carries the ``/api/v1/`` JSON routes) so the two URL
namespaces never collide.
"""

from __future__ import annotations

from django.urls import path

from .web_views import web_history

app_name = "historyshare_web"

urlpatterns = [
    path("h/<str:token>", web_history, name="web-history"),
]
