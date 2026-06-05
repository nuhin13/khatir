"""Warnings service layer — issue + list, strictly scoped + audited (T-002 §2).

Views stay thin (gate → validate → call a service → serialize). A warning is
*intrinsically private*: it is always created for the issuing landlord's **own**
lease and tenant, and the issuing ``landlord`` is taken from ``request.user`` —
never the client. The lease is resolved through ``Lease.objects.for_user`` so a
foreign/unknown lease is invisible (resolved to 404 by the view), and the
warning's tenant is copied from that lease, never supplied by the client. Every
issue writes an :class:`~khatir.core.models.AuditEntry` (``warning.issue``).
"""

from __future__ import annotations

from typing import Any

from django.db import transaction

from khatir.accounts.models import User
from khatir.core.audit import audit
from khatir.leases.models import Lease

from .enums import WarningType
from .models import Warning


def _snapshot(warning: Warning) -> dict[str, Any]:
    """A JSON-safe audit snapshot of the issued warning."""
    return {
        "lease_id": str(warning.lease_id),
        "tenant_id": str(warning.tenant_id),
        "landlord_id": str(warning.landlord_id),
        "warning_type": warning.warning_type,
        "reason": warning.reason,
    }


def issue_warning(
    *,
    actor: User,
    lease: Lease,
    warning_type: str = WarningType.OTHER,
    reason: str,
) -> Warning:
    """Issue a warning on ``lease`` for ``actor`` (the issuing landlord).

    ``lease`` must already have been resolved through the caller's
    ``for_user`` scope, so it is guaranteed to belong to ``actor``. The
    warning's tenant is copied from the lease — never accepted from the client —
    and ``landlord`` is ``actor``. Audited as ``warning.issue``.
    """
    with transaction.atomic():
        warning = Warning.objects.create(
            lease=lease,
            tenant_id=lease.tenant_id,
            landlord=actor,
            warning_type=warning_type,
            reason=reason,
        )

    audit(
        actor=actor,
        action="warning.issue",
        target=warning,
        before=None,
        after=_snapshot(warning),
    )
    return warning
