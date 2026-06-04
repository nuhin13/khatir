"""Public rent web routes (EPIC-07 T-005).

``/r/<token>`` is the no-login tenant pay page. It lives outside ``/api/v1/``
because it is a browser-facing HTML page, not a JSON API. Kept in its own module
(separate from ``urls.py``, which carries the ``/api/v1/`` JSON routes) so the
two URL namespaces never collide.
"""

from __future__ import annotations

from django.urls import path

from .web_views import web_pay

app_name = "rent_web"

urlpatterns = [
    path("r/<str:token>", web_pay, name="web-pay"),
]
