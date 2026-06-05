"""History-sharing services — EPIC-24.T-002 (tenant-initiated share).

All business logic for creating a :class:`~khatir.historyshare.models.HistoryShare`
lives here; the view only validates input, resolves the caller, and serializes.

A share is created **by the tenant** and only by the tenant — there is no
landlord-initiated lookup anywhere. Creating a share, atomically:

* re-checks the ``history_flags_feature`` kill-switch (defence in depth — the
  view gates too, but the service is the single place that performs the write);
* logs a fresh, time-stamped :class:`~khatir.compliance.models.ConsentRecord`
  (``pdpa_data_sharing``) for THIS share — consent is per-share, never reused;
* snapshots FACTUAL stats via :func:`compute_factual_stats` so a recipient sees
  a frozen, subjective-free record and the read path never touches live data;
* writes a customer-facing :func:`~khatir.core.audit.audit` entry.

The whole operation is wrapped in a transaction so a partial failure never
leaves an orphaned consent record or an un-audited share.
"""

from __future__ import annotations

import datetime
from typing import Any

from django.db import transaction
from django.utils import timezone

from khatir.compliance.enums import ConsentType
from khatir.compliance.models import ConsentRecord
from khatir.core.audit import audit
from khatir.core.exceptions import FeatureDisabledError, ValidationError
from khatir.tenants.models import Tenant

from .flags import history_sharing_enabled
from .models import HistoryShare
from .stats import compute_factual_stats


def resolve_acting_tenant(user: Any) -> Tenant:
    """Return the :class:`Tenant` identity the calling ``user`` owns.

    A tenant app account is linked to its identity record via
    ``Tenant.linked_user``. If the caller has no linked tenant record there is
    nothing to share, so this raises :class:`ValidationError` rather than
    silently creating a share for the wrong identity.
    """
    tenant = Tenant.objects.filter(linked_user=user).order_by("pk").first()
    if tenant is None:
        raise ValidationError(
            "No tenant profile is linked to this account, so there is no "
            "rental history to share."
        )
    return tenant


@transaction.atomic
def create_history_share(
    *,
    acting_user: Any,
    recipient_landlord: Any,
    scope: dict[str, Any] | None = None,
    expires_at: datetime.datetime | None = None,
) -> HistoryShare:
    """Create a tenant-initiated, consent-gated, factual-only history share.

    ``acting_user`` is taken from ``request.user`` (never the client body) and
    must own a tenant identity. ``recipient_landlord`` is the prospective
    landlord the tenant chose. Returns the created :class:`HistoryShare`.

    Raises :class:`FeatureDisabledError` when the kill-switch is off and
    :class:`ValidationError` when the caller has no tenant identity or
    ``expires_at`` is in the past.
    """
    if not history_sharing_enabled():
        raise FeatureDisabledError(
            "Rental-history sharing is currently unavailable."
        )

    tenant = resolve_acting_tenant(acting_user)

    now = timezone.now()
    if expires_at is not None and expires_at <= now:
        raise ValidationError("The expiry must be in the future.")

    # Per-share consent: a fresh, time-stamped record logged for THIS share,
    # mirroring its expiry so the consent and the share lapse together.
    consent_record = ConsentRecord.objects.create(
        user=acting_user,
        consent_type=ConsentType.PDPA_DATA_SHARING,
        granted_at=now,
        expires_at=expires_at,
    )

    share = HistoryShare.objects.create(
        tenant=tenant,
        recipient_landlord=recipient_landlord,
        scope=scope or {},
        consent_record=consent_record,
        factual_stats=dict(compute_factual_stats(tenant)),
        expires_at=expires_at,
    )

    audit(
        actor=acting_user,
        action="history_share.create",
        target=share,
        before=None,
        after={
            "tenant_id": share.tenant_id,
            "recipient_landlord_id": share.recipient_landlord_id,
            "consent_record_id": share.consent_record_id,
            "expires_at": expires_at.isoformat() if expires_at else None,
        },
    )
    return share
