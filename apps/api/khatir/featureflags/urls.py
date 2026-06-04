"""Admin feature-flag routes — EPIC-13.T-002.

Mounted at ``/admin/api/`` from ``config/urls.py`` (alongside the rest of the
admin-portal application API). Exposes the ``flags`` resource:

* ``/admin/api/flags``              — list / create
* ``/admin/api/flags/{key}``        — retrieve / update (lookup by flag ``key``)
* ``/admin/api/flags/{key}/toggle`` — flip ``enabled``
"""

from rest_framework.routers import DefaultRouter

from .views import FeatureFlagViewSet

app_name = "featureflags"

router = DefaultRouter(trailing_slash=False)
router.register("flags", FeatureFlagViewSet, basename="flag")

urlpatterns = [
    *router.urls,
]
