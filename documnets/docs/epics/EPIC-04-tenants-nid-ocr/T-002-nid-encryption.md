---
id: T-002
epic: EPIC-04
title: NID encryption + masking integration
layer: backend
size: S
status: done
preferred_agent: claude-code
depends_on: [T-001]
blocks: [T-007]
external_services: []
feature_flags: []
started_at:
completed_at: 2026-06-04
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-002 · NID encryption + masking integration

## 1. Feature goal
Wire the `core.encryption` helpers into the Tenant model so the NID number is encrypted on write and masked for display, with decryption only when explicitly needed.

## 2. Business logic
On set NID: store Fernet-encrypted bytes in `nid_number_enc` + `****` + last4 in `nid_number_masked`. Decryption is an explicit method (audited where used). Never log plaintext.

## 3. What this task DOES
- Model property/methods: `set_nid(raw)`, `get_nid()` (explicit decrypt), masking on save.
- Serializer never exposes full NID by default (only masked); a separate explicit, permissioned path for full (used by DMP form generation EPIC-05).
- Tests: round-trip, masking format, serializer hides full NID.

## 5. Files & changes
### Add
- tenants/tests/test_encryption.py
### Update
- tenants/models.py (set_nid/get_nid/masking)

## 6. Database changes
None.
## 7. API changes
None directly.
## 8. UI changes
No UI.
## 9. External services
None.
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] set_nid encrypts + sets masked
- [ ] get_nid explicit decrypt (no implicit exposure)
- [ ] serializer default exposes masked only
- [ ] Tests: round-trip, mask format, serializer hides full
- [ ] no plaintext logging
- [ ] ruff + mypy clean

## 12. Test plan
### Automated
- test_set_get_nid, test_masked_format (****last4), test_serializer_masked_only
### Manual QA
1. Create tenant w/ NID; DB shows enc bytes + masked; API returns masked.

## 13. Acceptance criteria
- [ ] NID encrypted + masked; full only via explicit permissioned path; tests + lint pass.

## 14. Self-review
- [ ] No code path logs or serializes full NID by default
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Uses core.encryption (EPIC-00 T-005) Fernet + FIELD_ENCRYPTION_KEY. The full-NID path is needed by EPIC-05 DMP form — expose a clearly-named, audited method, not a serializer field.
