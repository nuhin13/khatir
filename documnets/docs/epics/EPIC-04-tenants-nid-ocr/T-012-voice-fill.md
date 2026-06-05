---
id: T-012
epic: EPIC-04
title: Flutter voice-fill screen
layer: mobile
size: M
status: done
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
- [x] record audio (mic perm) + indicator
- [x] upload to /tenants/voice
- [x] loading + error states
- [x] prefill review (reuse T-011) from ASR fields
- [x] flag-gated
- [x] route /tenants/add/voice
- [x] ARB bn + en; widget test (mocked)
- [x] analyze + test pass

## 12. Test plan
### Automated
- voice_fill_test → record→upload→review prefilled; flag off → not reachable
### Manual QA
1. Speak details → review prefilled → correct → save.

## 13. Acceptance criteria
- [x] Voice path records, extracts, prefills review, saves.
- [x] **Screen `voice` built** (ledger row).
- [x] Test + analyze pass.

## 14. Self-review
- [x] Audio not retained on device post-upload; flag respected; tokens used
### Deviations from spec
- Audio recording is abstracted behind an `AudioRecorderService` interface
  (mirroring the OCR `ImagePickerService`) so widget tests inject a fake without
  the platform-channel `record` plugin or a live mic. The default
  `PluginAudioRecorder` (`record: ^6.2.0`) owns the mic-permission prompt
  (`hasPermission()`), records to a temp file, reads it for the upload, then
  deletes the temp file — the clip is never persisted beyond the upload (§14).
  Added `RECORD_AUDIO` (Android) + `NSMicrophoneUsageDescription` (iOS).
- Review step is the **reused** `OcrReviewScreen` (T-011), unchanged, per §15 —
  the voice flow only differs in source. The voice `POST /tenants/voice`
  response omits `photo_ref` (T-006 §7), so `ExtractedTenant.photoRef` degrades
  to an empty string for the voice path.
- Defensive flag gate: the chooser (T-009) already hides the voice entry when
  `voice_tenant_entry` is off; the screen also re-checks the flag so a deep link
  cannot bypass the gate (renders an "unavailable" state instead of the mic).
- Mic uses hold-to-talk (press = record, release = upload), matching the proto's
  "hold & speak" affordance.
### Files touched (actual)
- apps/mobile/lib/features/tenants/presentation/screens/voice_fill_screen.dart — new screen
- apps/mobile/lib/features/tenants/data/tenant_repository.dart — `voiceExtract`
- apps/mobile/lib/features/tenants/data/tenants_providers.dart — `AudioRecorderService` / `PluginAudioRecorder` / `RecordedAudio` / provider
- apps/mobile/lib/core/network/api_endpoints.dart — `tenantVoice`
- apps/mobile/lib/core/router/app_router.dart — real `voice` route (was placeholder)
- apps/mobile/lib/l10n/app_en.arb, app_bn.arb — `voice_*` keys
- apps/mobile/pubspec.yaml — `record` dependency
- apps/mobile/android/.../AndroidManifest.xml — RECORD_AUDIO; ios/Runner/Info.plist — NSMicrophoneUsageDescription
- apps/mobile/test/voice_fill_test.dart — widget tests (new)

## 15. Notes for the implementing agent
- Reuse the OCR review form (T-011) for the editable step — same fields, different source. Don't duplicate the review UI.
