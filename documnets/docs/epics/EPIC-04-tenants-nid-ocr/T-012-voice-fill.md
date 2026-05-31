---
id: T-012
epic: EPIC-04
title: Flutter voice-fill screen
layer: mobile
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-006, T-009]
blocks: [T-016]
external_services: [asr]
feature_flags: [voice_tenant_entry]
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-012 · Flutter voice-fill screen

## 1. Feature goal
Let the landlord speak the tenant's details in Bangla; record audio, send to `/tenants/voice`, and prefill the editable review form.

## 2. Business logic
Per `voice` design. Record → upload → ASR fields → same editable review as OCR → save → DMP. Flag-gated (`voice_tenant_entry`). Mic permission handled.

## 3. What this task DOES
- Record UI (mic, waveform/indicator), upload, loading, then reuse the editable review (T-011 form) prefilled from ASR. Widget test (mocked).

## 5. Files & changes
### Add
- features/tenants/presentation/screens/voice_fill_screen.dart; ARB; test
### Update
- routing /tenants/add/voice

## 6. Database changes
None.
## 7. API changes
Consumes POST /tenants/voice.

## 8. UI changes
- **Design source:** screen `voice` — `docs/design/khatir-ui/proto/screens-landlord2.js` → `reg('voice')`
- Surface: mobile · **Lane:** 🟢 mobile
- Route: `/tenants/add/voice`
- Translate record UI; values from packages/design-tokens
- States: data (idle), recording, loading (ASR), error, → review
- Navigation: success → review (reuse T-011) → save+DMP (T-016)
- i18n keys: `voice_title`, `voice_tap_to_record`, `voice_recording`, `voice_processing`, `voice_error` (bn + en)

## 9. External services
ASR (via backend).
## 10. Feature flags
- voice_tenant_entry

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] record audio (mic perm) + indicator
- [ ] upload to /tenants/voice
- [ ] loading + error states
- [ ] prefill review (reuse T-011) from ASR fields
- [ ] flag-gated
- [ ] route /tenants/add/voice
- [ ] ARB bn + en; widget test (mocked)
- [ ] analyze + test pass

## 12. Test plan
### Automated
- voice_fill_test → record→upload→review prefilled; flag off → not reachable
### Manual QA
1. Speak details → review prefilled → correct → save.

## 13. Acceptance criteria
- [ ] Voice path records, extracts, prefills review, saves.
- [ ] **Screen `voice` built** (ledger row).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Audio not retained on device post-upload; flag respected; tokens used
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Reuse the OCR review form (T-011) for the editable step — same fields, different source. Don't duplicate the review UI.
