"""DMP form data assembler — field mapping (EPIC-05 T-002 seam).

``assemble_dmp_data(tenant)`` pulls a tenant, their family members, and (via the
most recent lease) the building and landlord into a single normalized
:class:`~khatir.dmpforms.dto.DmpData`. This is the *one* place that knows the
official DMP field mapping.

The full NID is read only through the audited decrypt path (``actor`` is passed
through and an ``audit`` row is written); the decrypted value is never logged.
The exact official field list is reconciled by T-010 — the production assembler
(T-002) fleshes out the mapping; T-005 orchestrates and mocks this seam.
"""

from __future__ import annotations

from typing import Any

from khatir.core.audit import audit

from .dto import DmpData, FamilyMemberData


def _decrypt_nid(tenant: Any, *, actor: Any | None) -> str:
    """Decrypt the tenant's NID through the audited path; return "" if absent.

    Writes a ``tenant.nid_access`` audit row whenever a decrypt is attempted so
    every access to the full NID is recorded (the plaintext is never logged).
    """
    enc = getattr(tenant, "nid_number_enc", None)
    if not enc:
        return ""

    from khatir.core.encryption import decrypt

    audit(actor=actor, action="tenant.nid_access", target=tenant)
    token = enc.tobytes().decode("utf-8") if isinstance(enc, memoryview) else bytes(enc).decode(
        "utf-8"
    )
    return decrypt(token)


def assemble_dmp_data(tenant: Any, *, actor: Any | None = None) -> DmpData:
    """Assemble all DMP form fields for ``tenant`` into a ``DmpData``.

    ``actor`` is the user triggering generation; it is threaded into the audited
    NID decrypt path. Building and landlord come from the tenant's most recent
    lease (if any).
    """
    family = tuple(
        FamilyMemberData(name=member.name, relation=member.relation)
        for member in tenant.family_members.all()
    )

    lease = tenant.leases.order_by("-start_date").first()
    building_address = ""
    building_area = ""
    landlord_name = ""
    landlord_phone = ""
    if lease is not None:
        building = getattr(getattr(lease, "unit", None), "building", None)
        if building is not None:
            building_address = getattr(building, "address", "") or ""
            building_area = getattr(building, "area", "") or ""
        landlord = getattr(lease, "landlord", None)
        if landlord is not None:
            landlord_name = getattr(landlord, "name", "") or ""
            landlord_phone = getattr(landlord, "phone", "") or ""

    return DmpData(
        tenant_name=tenant.name,
        nid_number=_decrypt_nid(tenant, actor=actor),
        dob=tenant.dob.isoformat() if getattr(tenant, "dob", None) else "",
        permanent_address=getattr(tenant, "address", "") or "",
        building_address=building_address,
        building_area=building_area,
        landlord_name=landlord_name,
        landlord_phone=landlord_phone,
        family_members=family,
    )


__all__ = ["assemble_dmp_data"]
