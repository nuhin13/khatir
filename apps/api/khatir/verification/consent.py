"""Consent capture for NID/EC verification — EPIC-17 T-003.

Under PDPA, **explicit consent** must be recorded before any identity
verification runs. Consent here is the landlord/operator attesting that they
hold the tenant's permission to verify their NID against the Election
Commission. The attestation is logged as a ``compliance.ConsentRecord`` with
``consent_type = PDPA_NID_VERIFICATION``.

A consent is *valid* for a tenant when there exists, among the consent records
under which that tenant has been (or is being) verified, at least one
``PDPA_NID_VERIFICATION`` record that is neither revoked nor expired.

This module exposes two helpers used by the verify endpoint (T-004):

* :func:`record_verification_consent` — write a fresh consent record.
* :func:`has_valid_consent` — guard that refuses verification without one.
"""

from __future__ import annotations

from django.db.models import Q
from django.utils import timezone

from khatir.accounts.models import User
from khatir.compliance.enums import ConsentType
from khatir.compliance.models import ConsentRecord
from khatir.tenants.models import Tenant


def record_verification_consent(tenant: Tenant, by_user: User) -> ConsentRecord:
    """Record explicit ``PDPA_NID_VERIFICATION`` consent for verifying ``tenant``.

    ``by_user`` is the landlord/operator attesting they hold the tenant's
    permission. Returns the created (append-only) :class:`ConsentRecord`, which
    the caller links to the resulting ``VerificationLog`` (T-004).
    """
    return ConsentRecord.objects.create(
        user=by_user,
        consent_type=ConsentType.PDPA_NID_VERIFICATION,
        granted_at=timezone.now(),
    )


def has_valid_consent(tenant: Tenant) -> bool:
    """Return ``True`` if ``tenant`` has a currently-valid verification consent.

    A consent record is valid when it is of type ``PDPA_NID_VERIFICATION``,
    has not been revoked, and has not expired. Consent is scoped to the tenant
    via the verification logs that reference it.
    """
    now = timezone.now()
    return ConsentRecord.objects.filter(
        verification_logs__tenant=tenant,
        consent_type=ConsentType.PDPA_NID_VERIFICATION,
        revoked_at__isnull=True,
    ).filter(
        Q(expires_at__isnull=True) | Q(expires_at__gt=now)
    ).exists()
