"""Root URL configuration.

``/healthz`` is unversioned (load-balancer probe). All application routes are
mounted under ``/api/v1/``.
"""

from django.contrib import admin
from django.urls import include, path
from drf_spectacular.views import (
    SpectacularAPIView,
    SpectacularRedocView,
    SpectacularSwaggerView,
)

from khatir.health.views import healthz

urlpatterns = [
    # Admin-portal staff auth (EPIC-11.T-003) — separate JWT realm. Listed
    # before the Django ``admin/`` site so the more specific prefix matches.
    path("admin/api/auth/", include("khatir.admin_portal.urls")),
    # Admin-portal application API (EPIC-11.T-005) — platform dashboard etc.
    path("admin/api/", include("khatir.admin_portal.admin_urls")),
    # Admin feature-flag CRUD/toggle (EPIC-13.T-002) — /admin/api/flags.
    path("admin/api/", include("khatir.featureflags.urls")),
    path("admin/", admin.site.urls),
    path("healthz", healthz, name="healthz"),
    # Public, no-login tenant pay page (token-scoped). Browser HTML, so it
    # lives at the root rather than under ``/api/v1/``.
    path("", include("khatir.rent.web_urls")),
    path("api/v1/", include("khatir.health.urls")),
    path("api/v1/", include("khatir.accounts.profile_urls")),
    path("api/v1/", include("khatir.properties.urls")),
    path("api/v1/", include("khatir.tenants.urls")),
    path("api/v1/", include("khatir.leases.urls")),
    path("api/v1/", include("khatir.dmpforms.urls")),
    path("api/v1/", include("khatir.rent.urls")),
    path("api/v1/", include("khatir.maintenance.urls")),
    path("api/v1/", include("khatir.billing.urls")),
    path("api/v1/auth/", include("khatir.accounts.urls")),
    # OpenAPI schema + interactive docs (drf-spectacular).
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path(
        "api/docs/",
        SpectacularSwaggerView.as_view(url_name="schema"),
        name="swagger-ui",
    ),
    path(
        "api/redoc/",
        SpectacularRedocView.as_view(url_name="schema"),
        name="redoc",
    ),
]
