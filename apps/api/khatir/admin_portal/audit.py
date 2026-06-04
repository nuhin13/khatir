"""Admin audit writer — T-002 (Domain 8 of ``06_database_schema.md``).

Every consequential admin-portal write must record an immutable
:class:`~khatir.admin_portal.models.AdminAuditEntry`. This is the **only**
sanctioned way to create those rows::

    admin_audit(
        admin_user=request.admin_user,
        action="admin_user.disable",
        entity=target_admin,
        before={"disabled": False},
        after={"disabled": True},
        ip=request.META.get("REMOTE_ADDR"),
        reason="Offboarding per HR ticket #123",
    )

``before``/``after`` should be field-level diffs where practical, not full
object dumps (see task §15).
"""

from __future__ import annotations

from typing import Any

from django.db import models

from .models import AdminAuditEntry, AdminUser


def admin_audit(
    *,
    admin_user: AdminUser | None,
    action: str,
    entity: models.Model | None = None,
    before: dict[str, Any] | None = None,
    after: dict[str, Any] | None = None,
    ip: str | None = None,
    reason: str = "",
) -> AdminAuditEntry:
    """Write an :class:`AdminAuditEntry` row and return it.

    ``admin_user`` is the acting staff account (``None`` for system actions).
    ``entity`` is the affected model instance; its ``app_label.model_name`` and
    primary key are denormalized onto ``entity_type``/``entity_id``.
    """
    entity_type = ""
    entity_id = ""
    if entity is not None:
        entity_type = f"{entity._meta.app_label}.{entity._meta.model_name}"
        entity_id = str(entity.pk) if entity.pk is not None else ""

    return AdminAuditEntry.objects.create(
        admin_user=admin_user if (admin_user is not None and admin_user.pk) else None,
        action=action,
        entity_type=entity_type,
        entity_id=entity_id,
        before_json=before,
        after_json=after,
        ip=ip or None,
        reason=reason,
    )
