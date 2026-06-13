# DMP Form — Official Field Map (T-010)

> Release-gate reference for the DMP tenant-registration wedge.
> Template version: **`2026.1`** (seeded as the `dmp_template_version` SystemConfig
> key by EPIC-05 T-006). Bump this when the official form layout changes; old
> `DMPFormRecord` rows keep the version they were generated with.

## 1. Purpose

This document is the single canonical list of the fields on the official Dhaka
Metropolitan Police (DMP) tenant-registration form (ভাড়াটিয়া তথ্য ফরম) that the
Khatir wedge fills in. Every field below is reconciled across three layers:

1. **DTO** — `khatir.dmpforms.dto.DmpData` (the normalized shape).
2. **Assembler** — `khatir.dmpforms.assembler.assemble_dmp_data` (Tenant + lease →
   `DmpData`).
3. **Renderer** — `khatir.dmpforms.pdf` (`DmpData` + template version → PDF bytes),
   whose field positions are locked by the golden test
   `tests/test_template_verification.py`.

If the official form changes, update this table, the renderer's `FIELD_LAYOUT`,
and the golden test together, then bump `dmp_template_version`.

## 2. Verification status

| Aspect | Status |
| --- | --- |
| Canonical field list documented | ✅ this file |
| DTO carries every field below | ✅ `DmpData` |
| Assembler maps every field the MVP data model captures | ✅ `assemble_dmp_data` |
| Renderer emits every field at a named, fixed position | ✅ `FIELD_LAYOUT` |
| Golden field-position test locks the rendered field set | ✅ `test_template_verification.py` |
| Pixel/overlay match against the **authoritative scanned form** | ⏳ requires the founder to supply the scanned master (T-010 §15). The renderer positions below are the documented baseline; only the position constants need confirming once the scan is in hand — the field set and golden test are already locked. |

## 3. Field map

`*` marks a field the MVP data model does not yet capture (rendered blank /
hand-completed). It is listed so the form is complete and so a future task can
wire it without changing the contract.

| # | Official field (bn / en) | `DmpData` attribute | Assembler source |
| --- | --- | --- | --- |
| 1 | ভাড়াটিয়ার নাম / Tenant name | `tenant_name` | `Tenant.name` |
| 2 | জাতীয় পরিচয়পত্র নম্বর / NID number | `nid_number` | `Tenant.nid_number_enc` (audited decrypt) |
| 3 | জন্ম তারিখ / Date of birth | `dob` | `Tenant.dob` |
| 4 | স্থায়ী ঠিকানা / Permanent address | `permanent_address` | `Tenant.address` |
| 5 | বর্তমান ঠিকানা / Present address | `present_address` | `Tenant.address` (same MVP source) |
| 6 | বাসা/ভবনের ঠিকানা / Building (rented) address | `building_address` | `Lease.unit.building.address` |
| 7 | এলাকা / Area | `building_area` | `Lease.unit.building.area` |
| 8 | বাড়িওয়ালার নাম / Landlord name | `landlord_name` | `Lease.landlord.name` |
| 9 | বাড়িওয়ালার মোবাইল / Landlord phone | `landlord_phone` | `Lease.landlord.phone` |
| 10 | পরিবারের সদস্য (নাম / সম্পর্ক) / Family members (name / relation) | `family_members[]` (`name`, `relation`) | `Tenant.family_members` |

### Known gaps (not in the MVP data model)

These appear on the official form but are not captured by the current schema, so
the generated PDF leaves them blank for hand-completion. Tracked here so the
field set stays auditable:

- পিতার নাম / Father's name `*`
- মাতার নাম / Mother's name `*`
- পেশা / Profession `*`
- ভাড়াটিয়ার মোবাইল / Tenant phone `*`
- ভাড়ার পরিমাণ / Rent amount `*`
- চুক্তির তারিখ / Tenancy start date `*`

## 4. Renderer contract (locked by the golden test)

`khatir.dmpforms.pdf.FIELD_LAYOUT` is an ordered tuple of `FieldSpec(key, label,
x, y)` entries — one per row 1–9 above, plus a repeating family-member block.
The renderer draws each `DmpData` value at its spec's `(x, y)` on a single
Letter page. The golden test asserts:

1. every official field key in this table is present in `FIELD_LAYOUT`;
2. each field's value is rendered (the assembled text appears in the PDF
   content stream at a stable position);
3. output is byte-for-byte deterministic for a fixed input + version.

This is the field-by-field fidelity gate. Changing any position is a template
change → bump `dmp_template_version`.
