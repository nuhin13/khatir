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
from khatir.core.exceptions import FeatureDisabledError, NotFoundError, ValidationError
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


def list_history_shares(*, acting_user: Any) -> Any:
    """Return the calling tenant's OWN shares, newest first.

    Full transparency: the tenant sees every share they originated regardless
    of lifecycle state (active / expired / revoked) — that is the point of the
    transparency view. Strictly scoped to ``request.user``'s tenant identity so
    one tenant can never see another's shares. ``consent_record`` is selected so
    status/consent computation never N+1s.
    """
    tenant = resolve_acting_tenant(acting_user)
    return (
        HistoryShare.objects.filter(tenant=tenant)
        .select_related("consent_record", "recipient_landlord")
        .order_by("-created_at")
    )


@transaction.atomic
def revoke_history_share(*, acting_user: Any, share_id: int) -> HistoryShare:
    """Instantly revoke one of the calling tenant's OWN shares.

    Only the owning tenant may revoke, and only their own share — a share that
    does not belong to the caller is reported as not found (404), never as
    forbidden, so existence of another tenant's share never leaks. Revoking is
    idempotent: re-revoking an already-revoked share is a no-op that returns the
    share unchanged (the original ``revoked_at`` is preserved).

    Revoking kills the share immediately (``revoked_at = now``) AND withdraws the
    linked per-share consent (``ConsentRecord.revoked_at``) so the recipient read
    path closes via both gates. Audited. Kill-switch independent — a tenant must
    ALWAYS be able to withdraw, even if the feature is otherwise disabled.
    """
    tenant = resolve_acting_tenant(acting_user)
    share = (
        HistoryShare.objects.select_related("consent_record")
        .filter(pk=share_id, tenant=tenant)
        .first()
    )
    if share is None:
        raise NotFoundError("This shared rental history was not found.")

    if share.revoked_at is not None:
        return share  # idempotent — already revoked, preserve the original time.

    now = timezone.now()
    share.revoked_at = now
    share.save(update_fields=["revoked_at", "updated_at"])

    # Withdraw the per-share consent too, so the share closes via both gates.
    consent = share.consent_record
    if consent.revoked_at is None:
        consent.revoked_at = now
        consent.save(update_fields=["revoked_at", "updated_at"])

    audit(
        actor=acting_user,
        action="history_share.revoke",
        target=share,
        before={"revoked_at": None},
        after={"revoked_at": now.isoformat()},
    )
    return share
