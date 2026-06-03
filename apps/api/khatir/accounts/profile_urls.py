"""Profile route mounted under ``/api/v1/`` (T-001 §7).

Kept separate from the ``/auth/`` urlconf because ``/profile`` is a top-level
resource, not part of the auth namespace. Bearer auth is required (the view's
``IsAuthenticated``); the endpoint is always scoped to ``request.user``.
"""

from django.urls import path

from .views import ProfileView

app_name = "profile"

urlpatterns = [
    path("profile", ProfileView.as_view(), name="profile"),
]
