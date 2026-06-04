"""Admin notification-template endpoints — EPIC-15.T-008.

Mounted at ``/admin/api/notification-templates`` (see
:mod:`khatir.notifications.urls`, included from ``config/urls.py``). All routes
require a valid admin Bearer token and a ``platform`` section role
(``super`` / ``ops``) — the same gate the feature-flag console uses (task §6:
super+ops).

* ``GET   /admin/api/notification-templates``         — list every template.
* ``POST  /admin/api/notification-templates``         — create a template.
* ``GET   /admin/api/notification-templates/{key}``   — retrieve one template.
* ``PATCH /admin/api/notification-templates/{key}``   — edit title/body/channels.

Templates are editable (title/body/channels/variables/active) but ``key`` and
``trigger_event`` are immutable (enforced by the serializer). Every write is
audited via :func:`khatir.admin_portal.audit.admin_audit` (task §6: admin
audit). No deletes — templates are deactivated via ``active`` rather than
removed.
"""

from __future__ import annotations

from typing import cast

from rest_framework import mixins, viewsets
from rest_framework.permissions import BasePermission
from rest_framework.request import Request

from khatir.admin_portal.audit import admin_audit
from khatir.admin_portal.authentication import (
    AdminJWTAuthentication,
    IsAdminAuthenticated,
)
from khatir.admin_portal.models import AdminUser
from khatir.admin_portal.permissions import SECTION_ROLES, AdminSection

from .models import NotificationTemplate
from .serializers import NotificationTemplateSerializer


def _client_ip(request: Request) -> str | None:
    return request.META.get("REMOTE_ADDR")


class IsPlatformAdmin(BasePermission):
    """Gate template endpoints on the ``platform`` section roles (super / ops).

    Reads the role off the ``AdminUser`` loaded by ``AdminJWTAuthentication``,
    mirroring the feature-flag console so authz stays consistent across the
    admin portal. ``super`` is always inside the platform section set.
    """

    def has_permission(self, request: Request, view: object) -> bool:
        admin_user = getattr(request, "admin_user", None)
        if not isinstance(admin_user, AdminUser) or admin_user.disabled:
            return False
        return admin_user.role in SECTION_ROLES[AdminSection.PLATFORM]


class NotificationTemplateViewSet(
    mixins.ListModelMixin,
    mixins.CreateModelMixin,
    mixins.RetrieveModelMixin,
    mixins.UpdateModelMixin,
    viewsets.GenericViewSet,
):
    """List/create/retrieve/update notification templates (super/ops only)."""

    queryset = NotificationTemplate.objects.all()
    serializer_class = NotificationTemplateSerializer
    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsAdminAuthenticated, IsPlatformAdmin]
    lookup_field = "key"
    lookup_value_regex = "[^/]+"

    def perform_create(
        self, serializer: NotificationTemplateSerializer
    ) -> None:
        admin_user = cast(AdminUser, self.request.admin_user)  # type: ignore[attr-defined]
        template = serializer.save()
        admin_audit(
            admin_user=admin_user,
            action="notification_template.create",
            entity=template,
            before=None,
            after={
                "key": template.key,
                "trigger_event": template.trigger_event,
                "channels": template.channels,
                "active": template.active,
            },
            ip=_client_ip(self.request),
        )

    def perform_update(
        self, serializer: NotificationTemplateSerializer
    ) -> None:
        admin_user = cast(AdminUser, self.request.admin_user)  # type: ignore[attr-defined]
        instance = serializer.instance
        before = {
            "title_en": instance.title_en,
            "title_bn": instance.title_bn,
            "body_en": instance.body_en,
            "body_bn": instance.body_bn,
            "channels": instance.channels,
            "variables": instance.variables,
            "active": instance.active,
        }
        template = serializer.save()
        admin_audit(
            admin_user=admin_user,
            action="notification_template.update",
            entity=template,
            before=before,
            after={
                "title_en": template.title_en,
                "title_bn": template.title_bn,
                "body_en": template.body_en,
                "body_bn": template.body_bn,
                "channels": template.channels,
                "variables": template.variables,
                "active": template.active,
            },
            ip=_client_ip(self.request),
        )
