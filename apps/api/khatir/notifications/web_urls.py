"""Public delivery-tracking web routes — EPIC-15 T-004.

Mounted at the project root from ``config/urls.py`` (alongside the rent and
maintenance public web surfaces), because these are hit by recipient browsers
and external messaging providers rather than the authenticated app:

* ``/n/<token>/open.gif``    — open beacon (1×1 tracking pixel)
* ``/n/<token>/delivered``   — provider delivery-confirmation webhook

Both are scoped solely by a signed :mod:`khatir.notifications.tracking` token.
Kept in their own module (separate from ``urls.py``, which carries the
``/admin/api/`` JSON routes) so the two URL namespaces never collide.
"""

from __future__ import annotations

from django.urls import path

from .web_views import delivery_webhook, open_beacon

app_name = "notifications_web"

urlpatterns = [
    path("n/<str:token>/open.gif", open_beacon, name="open-beacon"),
    path("n/<str:token>/delivered", delivery_webhook, name="delivery-webhook"),
]
