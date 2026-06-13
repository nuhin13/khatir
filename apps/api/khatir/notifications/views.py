"""Admin notification endpoints — EPIC-15.T-007 / T-008.

Mounted at ``/admin/api/`` (see :mod:`khatir.notifications.urls`, included from
``config/urls.py``). All routes require a valid admin Bearer token and a
``platform`` section role (``super`` / ``ops``) — the same gate the feature-flag
console uses (task §6: super+ops).

**Templates (T-008)** — ``notification-templates`` resource:

* ``GET   /admin/api/notification-templates``         — list every template.
* ``POST  /admin/api/notification-templates``         — create a template.
* ``GET   /admin/api/notification-templates/{key}``   — retrieve one template.
* ``PATCH /admin/api/notification-templates/{key}``   — edit title/body/channels.

Templates are editable (title/body/channels/variables/active) but ``key`` and
``trigger_event`` are immutable (enforced by the serializer).

**Broadcasts (T-007)** — ``notifications`` resource:

* ``GET  /admin/api/notifications``            — list broadcasts (newest first).
* ``POST /admin/api/notifications``            — compose + dispatch a broadcast.
* ``GET  /admin/api/notifications/{id}``       — retrieve one + its deliveries.
* ``POST /admin/api/notifications/{id}/send-test`` — deliver to the acting admin
  only (a preview send; no audience fan-out, no counters touched).

Every consequential write is audited via
:func:`khatir.admin_portal.audit.admin_audit` (task §6): compose is audited
inside the service (``notification.compose``); the send-test preview is audited
here (``notification.send_test``).
"""

from __future__ import annotations

from typing import cast

from rest_framework import mixins, status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import BasePermission
from rest_framework.request import Request
from rest_framework.response import Response

from khatir.admin_portal.audit import admin_audit
from khatir.admin_portal.authentication import (
    AdminJWTAuthentication,
    IsAdminAuthenticated,
)
from khatir.admin_portal.models import AdminUser
from khatir.admin_portal.permissions import SECTION_ROLES, AdminSection
from khatir.core.enums import Channel
from khatir.core.exceptions import ValidationError as DomainValidationError
from khatir.messaging import get_sender

from .models import Notification, NotificationTemplate
from .serializers import (
    NotificationComposeSerializer,
    NotificationDetailSerializer,
    NotificationSerializer,
    NotificationTemplateSerializer,
)
from .services import compose_notification


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


class NotificationViewSet(
    mixins.ListModelMixin,
    mixins.RetrieveModelMixin,
    viewsets.GenericViewSet,
):
    """List / retrieve / compose broadcasts and send a preview (super/ops only).

    Composition is delegated to
    :func:`khatir.notifications.services.compose_notification` (the single entry
    point that validates the audience, resolves reach, persists the row,
    dispatches/schedules delivery, and audits the write). ``send-test`` is a
    standalone preview that delivers the broadcast's content to the acting admin
    only — it never resolves the audience or mutates the broadcast's counters.
    """

    queryset = Notification.objects.all().prefetch_related("deliveries")
    authentication_classes = [AdminJWTAuthentication]
    permission_classes = [IsAdminAuthenticated, IsPlatformAdmin]

    def get_serializer_class(
        self,
    ) -> type[NotificationSerializer]:
        if self.action == "retrieve":
            return NotificationDetailSerializer
        return NotificationSerializer

    def create(self, request: Request, *args: object, **kwargs: object) -> Response:
        admin_user = cast(AdminUser, request.admin_user)  # type: ignore[attr-defined]
        payload = NotificationComposeSerializer(data=request.data)
        payload.is_valid(raise_exception=True)
        data = payload.validated_data

        try:
            result = compose_notification(
                admin_user=admin_user,
                audience_type=data["audience_type"],
                audience_filter=data.get("audience_filter") or {},
                channels=data["channels"],
                content={
                    "title_en": data["title_en"],
                    "title_bn": data["title_bn"],
                    "body_en": data["body_en"],
                    "body_bn": data["body_bn"],
                },
                schedule_type=data["schedule_type"],
                scheduled_at=data.get("scheduled_at"),
                recurrence=data.get("recurrence"),
                ip=_client_ip(request),
            )
        except DomainValidationError as exc:
            return Response(
                {"detail": str(exc)}, status=status.HTTP_400_BAD_REQUEST
            )

        body = NotificationSerializer(result.notification).data
        body["reach"] = result.reach
        body["estimated_cost"] = str(result.estimated_cost)
        return Response(body, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=["post"], url_path="send-test")
    def send_test(
        self, request: Request, *args: object, **kwargs: object
    ) -> Response:
        """Deliver the broadcast's content to the acting admin only.

        A preview send: the message is rendered (English variant) and pushed
        through the in-app/console sender addressed to the admin's email, so the
        author can sanity-check copy without fanning out to the real audience.
        Audited as ``notification.send_test``.
        """
        notification = cast(Notification, self.get_object())
        admin_user = cast(AdminUser, request.admin_user)  # type: ignore[attr-defined]

        message = f"{notification.title_en}\n\n{notification.body_en}".strip()
        sender = get_sender(Channel.INAPP)
        sender.send(admin_user.email, message, channel=Channel.INAPP)

        admin_audit(
            admin_user=admin_user,
            action="notification.send_test",
            entity=notification,
            after={
                "recipient": admin_user.email,
                "channel": Channel.INAPP.value,
            },
            ip=_client_ip(request),
        )
        return Response(
            {"detail": "Test notification sent.", "recipient": admin_user.email},
            status=status.HTTP_200_OK,
        )
