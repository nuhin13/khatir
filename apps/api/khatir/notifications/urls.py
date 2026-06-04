"""Admin notification-template routes — EPIC-15.T-008.

Mounted at ``/admin/api/`` from ``config/urls.py`` (alongside the rest of the
admin-portal application API). Exposes the ``notification-templates`` resource:

* ``/admin/api/notification-templates``         — list / create
* ``/admin/api/notification-templates/{key}``   — retrieve / update (by ``key``)
"""

from rest_framework.routers import DefaultRouter

from .views import NotificationTemplateViewSet

app_name = "notifications"

router = DefaultRouter(trailing_slash=False)
router.register(
    "notification-templates",
    NotificationTemplateViewSet,
    basename="notification-template",
)

urlpatterns = [
    *router.urls,
]
