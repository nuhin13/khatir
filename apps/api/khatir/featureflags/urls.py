"""Admin feature-flag + kill-switch routes — EPIC-13.T-002 / T-003.

Mounted at ``/admin/api/`` from ``config/urls.py`` (alongside the rest of the
admin-portal application API).

Feature-flag resource (T-002):

* ``/admin/api/flags``              — list / create
* ``/admin/api/flags/{key}``        — retrieve / update (lookup by flag ``key``)
* ``/admin/api/flags/{key}/toggle`` — flip ``enabled``

Kill-switch endpoints (T-003, super only):

* ``/admin/api/killswitches``               — list the 5 named switches
* ``/admin/api/killswitches/{key}/toggle``  — flip a switch (MFA re-confirm)
"""

from django.urls import path
from rest_framework.routers import DefaultRouter

from .killswitch_views import KillSwitchListView, KillSwitchToggleView
from .views import FeatureFlagViewSet

app_name = "featureflags"

router = DefaultRouter(trailing_slash=False)
router.register("flags", FeatureFlagViewSet, basename="flag")

urlpatterns = [
    *router.urls,
    path(
        "killswitches",
        KillSwitchListView.as_view(),
        name="killswitch-list",
    ),
    path(
        "killswitches/<str:key>/toggle",
        KillSwitchToggleView.as_view(),
        name="killswitch-toggle",
    ),
]
