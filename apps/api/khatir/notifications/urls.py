"""Admin notification routes — EPIC-15.T-007 / T-008.

Mounted at ``/admin/api/`` from ``config/urls.py`` (alongside the rest of the
admin-portal application API). Exposes two resources:

**Broadcasts (T-007)** — ``notifications``:

* ``/admin/api/notifications``                  — list / compose
* ``/admin/api/notifications/{id}``             — retrieve one + its deliveries
* ``/admin/api/notifications/{id}/send-test``   — preview send to the acting admin

**Templates (T-008)** — ``notification-templates``:

* ``/admin/api/notification-templates``         — list / create
* ``/admin/api/notification-templates/{key}``   — retrieve / update (by ``key``)
"""

from rest_framework.routers import DefaultRouter

from .views import NotificationTemplateViewSet, NotificationViewSet

app_name = "notifications"

router = DefaultRouter(trailing_slash=False)
router.register(
    "notifications",
    NotificationViewSet,
    basename="notification",
)
router.register(
    "notification-templates",
    NotificationTemplateViewSet,
    basename="notification-template",
)

urlpatterns = [
    *router.urls,
]
