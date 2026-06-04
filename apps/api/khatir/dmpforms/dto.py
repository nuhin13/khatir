"""Normalized DMP form data structures (EPIC-05 T-002 seam).

``DmpData`` is the single normalized shape every DMP renderer consumes — the
output of the assembler (T-002) and the input to the PDF renderer (T-003). It is
a plain dataclass (no Django models) so it is trivially serializable, testable,
and decoupled from the ORM.

The exact official field list is reconciled by T-010 (template verification);
this seam carries the core identity, household, building, and landlord fields
the pipeline needs. The full NID is only ever populated through the audited
decrypt path in the assembler — it is never logged.
"""

from __future__ import annotations

from dataclasses import dataclass, field


@dataclass(frozen=True)
class FamilyMemberData:
    """A household member printed on the DMP form."""

    name: str
    relation: str


@dataclass(frozen=True)
class DmpData:
    """All fields the DMP form needs, normalized for rendering."""

    tenant_name: str
    nid_number: str = ""  # full NID — audited decrypt only, never logged
    dob: str = ""
    permanent_address: str = ""
    present_address: str = ""
    building_address: str = ""
    building_area: str = ""
    landlord_name: str = ""
    landlord_phone: str = ""
    family_members: tuple[FamilyMemberData, ...] = field(default_factory=tuple)


__all__ = ["DmpData", "FamilyMemberData"]
