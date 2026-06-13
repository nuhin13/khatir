"""Verification service layer — the verify orchestration (EPIC-17 T-004 §2).

:func:`verify_tenant` is the single entry point behind ``POST
/tenants/{id}/verify``. It runs the flow in a strict, fail-fast order:

1. **consent** (T-003) — record explicit ``PDPA_NID_VERIFICATION`` consent;
2. **decrypt** — pull the plaintext NID via the audited ``Tenant.get_nid`` path
   (the *only* sanctioned route to the raw number), audited as ``tenant.nid.decrypt``;
3. **provider** (T-002) — submit NID + name + DOB to the EC vendor and read back a
   **boolean-only** outcome (matched / not_matched / error);
4. **persist** — append an immutable :class:`VerificationLog` (T-001) linked to the
   consent, then transition ``Tenant.verification_status``;
5. **audit** — write a ``verification.verify`` audit row (no raw EC data, no NID).

The tier gate (EPIC-10 T-009) and the ``nid_verification_enabled`` kill-switch are
enforced by the *view* before this is ever called (so a blocked caller never reaches
the decrypt / provider seam). The raw NID lives only as a local inside this function
and is never logged, audited, or returned. Only the boolean result + the opaque
vendor ``provider_ref`` survive into storage.
"""

from __future__ import annotations

from functools import lru_cache

from django.db import transaction

from khatir.accounts.models import User
from khatir.core.audit import audit
from khatir.tenants.models import Tenant

from .consent import record_verification_consent
from .models import VerificationLog
from .providers import ECVerificationProvider, VerificationProvider

__all__ = ["get_verification_provider", "verify_tenant"]


@lru_cache(maxsize=1)
def get_verification_provider() -> VerificationProvider:
    """Return the configured EC verification provider (swappable, T-002).

    A single concrete vendor client for the MVP. Indirection lives here so the
    vendor can be swapped (or routed through the AI gateway) without touching the
    view/service callers — mirrors ``tenants.extraction.get_ocr_provider``.
    """
    return ECVerificationProvider()


def verify_tenant(*, actor: User, tenant: Tenant) -> VerificationLog:
    """Run the full verify flow for ``tenant`` and return the appended log.

    Captures consent, decrypts the NID via the audited path, calls the EC provider,
    writes an append-only :class:`VerificationLog` and transitions the tenant's
    ``verification_status``, all in one atomic write. ``actor`` is the
    landlord/manager taken from ``request.user`` by the view (never the client body),
    recorded as ``requested_by`` and the consent grantor. Returns the new log; the
    raw NID is never persisted or returned (only matched / not_matched / error + the
    opaque ``provider_ref``).
    """
    # 1. Consent (T-003): record the landlord/operator's explicit attestation.
    consent = record_verification_consent(tenant, actor)

    # 2. Decrypt via the single audited path. The plaintext lives only as a local
    #    here; it is never logged, audited, or returned. Empty string when no NID is
    #    on file — the vendor then returns a definitive not_matched / error.
    audit(actor=actor, action="tenant.nid.decrypt", target=tenant)
    nid = tenant.get_nid() or ""
    dob = tenant.dob.isoformat() if tenant.dob else ""

    # 3. Provider (T-002): boolean-only outcome; raw EC payload never crosses back.
    outcome = get_verification_provider().verify(nid=nid, name=tenant.name, dob=dob)

    # 4. Persist: append-only log linked to the consent, then flip tenant status.
    with transaction.atomic():
        log = VerificationLog.objects.create(
            tenant=tenant,
            requested_by=actor,
            result=outcome.result,
            provider_ref=outcome.provider_ref,
            consent_record=consent,
        )
        tenant.apply_verification_result(outcome.result)

    # 5. Audit (no raw EC data, no NID — only the boolean + opaque ref).
    audit(
        actor=actor,
        action="verification.verify",
        target=log,
        after={
            "tenant_id": tenant.pk,
            "result": outcome.result,
            "provider_ref": outcome.provider_ref,
        },
    )

    return log


def latest_verification(tenant: Tenant) -> VerificationLog | None:
    """Return the tenant's most recent verification log, or ``None`` if never run."""
    return tenant.verification_logs.order_by("-created_at").first()
