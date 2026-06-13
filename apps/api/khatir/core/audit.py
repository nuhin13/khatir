"""Audit writer.

Any create/update/delete on personal/sensitive data writes an ``AuditEntry``
(``04_coding_conventions.md`` §11)::

    audit(actor=user, action="tenant.create", target=tenant,
          before=None, after=snapshot(tenant))

Action strings are ``domain.verb``. This is the only sanctioned way to write
audit rows.
"""

from __future__ import annotations

from typing import Any

from django.db import models

from .models import AuditEntry


def audit(
    *,
    actor: Any | None,
    action: str,
    target: models.Model | None = None,
    before: dict[str, Any] | None = None,
    after: dict[str, Any] | None = None,
) -> AuditEntry:
    """Write an :class:`AuditEntry` row and return it.

    ``actor`` is the acting user (or ``None`` for system actions). ``target`` is
    the affected model instance; its type and pk are denormalized onto the entry.
    """
    target_type = ""
    target_id = ""
    if target is not None:
        target_type = f"{target._meta.app_label}.{target._meta.model_name}"
        target_id = str(target.pk) if target.pk is not None else ""

    return AuditEntry.objects.create(
        actor=actor if (actor is not None and getattr(actor, "pk", None)) else None,
        action=action,
        target_type=target_type,
        target_id=target_id,
        before=before,
        after=after,
    )
