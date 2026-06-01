"""Root URL configuration.

``/healthz`` is unversioned (load-balancer probe). All application routes are
mounted under ``/api/v1/``.
"""

from django.contrib import admin
from django.urls import include, path

from khatir.health.views import healthz

urlpatterns = [
    path("admin/", admin.site.urls),
    path("healthz", healthz, name="healthz"),
    path("api/v1/", include("khatir.health.urls")),
]
