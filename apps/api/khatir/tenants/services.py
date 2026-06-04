"""Tenants service layer — create/update with NID encryption + audit (T-007 §2).

Views stay thin (validate → call a service → serialize). The raw NID number is
encrypted via ``Tenant.set_nid`` and never persisted, serialized, or audited in
plaintext — audit snapshots record only the masked form (``04_coding_conventions``
§10/§11). Every mutation writes an :class:`~khatir.core.models.AuditEntry` with a
``tenant.verb`` action string.
"""

from __future__ import annotations

from typing import Any

from django.db import transaction

from khatir.accounts.models import User
from khatir.core.audit import audit

from .models import Tenant, TenantFamilyMember

# Plain (non-NID) tenant fields a client may write directly.
_WRITABLE_FIELDS = ("name", "dob", "address", "photo_ref", "verification_status")


def _snapshot(tenant: Tenant) -> dict[str, Any]:
    """A JSON-safe audit snapshot — masked NID only, never the plaintext."""

    def _coerce(value: Any) -> Any:
        return value.isoformat() if hasattr(value, "isoformat") else value

    data = {field: _coerce(getattr(tenant, field)) for field in _WRITABLE_FIELDS}
    data["nid_number_masked"] = tenant.nid_number_masked
    return data


def _set_family(tenant: Tenant, members: list[dict[str, Any]]) -> None:
    """Replace ``tenant``'s family members with ``members`` (idempotent write)."""
    tenant.family_members.all().delete()
    TenantFamilyMember.objects.bulk_create(
        [
            TenantFamilyMember(
                tenant=tenant, name=m["name"], relation=m["relation"]
            )
            for m in members
        ]
    )


def create_tenant(
    *,
    actor: User,
    nid_number: str | None = None,
    family_members: list[dict[str, Any]] | None = None,
    **fields: Any,
) -> Tenant:
    """Create a tenant, encrypting the NID and attaching family + photo_ref.

    The raw ``nid_number`` (e.g. from OCR review) is encrypted via
    ``set_nid`` — only the ciphertext + masked form are persisted. The whole
    write is atomic so a tenant never lands without its family rows. Audited as
    ``tenant.create`` (masked NID only).
    """
    data = {k: v for k, v in fields.items() if k in _WRITABLE_FIELDS}
    with transaction.atomic():
        tenant = Tenant(**data)
        tenant.set_nid(nid_number)
        tenant.save()
        if family_members:
            _set_family(tenant, family_members)

    audit(
        actor=actor,
        action="tenant.create",
        target=tenant,
        before=None,
        after=_snapshot(tenant),
    )
    return tenant


def update_tenant(
    *,
    actor: User,
    tenant: Tenant,
    nid_number: str | None = None,
    family_members: list[dict[str, Any]] | None = None,
    **fields: Any,
) -> Tenant:
    """Apply a partial update to ``tenant`` and audit it (``tenant.update``).

    Records the before/after of the masked snapshot — never the plaintext NID.
    Supplying ``family_members`` replaces the household set.
    """
    changes = {k: v for k, v in fields.items() if k in _WRITABLE_FIELDS}
    before = _snapshot(tenant)

    with transaction.atomic():
        for field, value in changes.items():
            setattr(tenant, field, value)
        if nid_number is not None:
            tenant.set_nid(nid_number)
        tenant.save()
        if family_members is not None:
            _set_family(tenant, family_members)

    after = _snapshot(tenant)
    if before == after and family_members is None:
        return tenant

    audit(
        actor=actor,
        action="tenant.update",
        target=tenant,
        before=before,
        after=after,
    )
    return tenant
