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
from khatir.core.storage import signed_url, store_encrypted
from khatir.leases.models import Lease

from .enums import WarningType
from .models import Warning
from .notice import render_notice_pdf


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


def generate_notice(*, actor: User, warning: Warning) -> str:
    """Generate (or regenerate) the warning-notice PDF and return a signed URL.

    ``warning`` must already have been resolved through the caller's ``for_user``
    scope, so it is guaranteed to belong to ``actor`` (the issuing landlord). The
    notice is rendered via the EPIC-05 PDF seam, stored encrypted-at-rest through
    the EPIC-04 storage seam (``kind="pdf"``), and its opaque storage key is
    persisted on ``warning.notice_ref``. Audited as ``warning.notice``. Returns a
    time-limited signed URL for retrieval — the object itself is never
    public-readable.
    """
    pdf_bytes = render_notice_pdf(warning)
    with transaction.atomic():
        warning.notice_ref = store_encrypted(pdf_bytes, kind="pdf")
        warning.save(update_fields=["notice_ref", "updated_at"])

    audit(
        actor=actor,
        action="warning.notice",
        target=warning,
        before=None,
        after={"notice_ref": warning.notice_ref},
    )
    return signed_url(warning.notice_ref)
