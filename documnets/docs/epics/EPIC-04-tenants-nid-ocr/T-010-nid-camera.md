---
id: T-010
epic: EPIC-04
title: Flutter NID camera capture + upload
layer: mobile
size: M
status: todo
preferred_agent: claude-code
depends_on: [T-005, T-009]
blocks: [T-011]
external_services: [ocr]
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-010 · Flutter NID camera capture + upload

## 1. Feature goal
Capture the NID photo (camera or gallery), upload to `/tenants/ocr`, show progress, and pass the extracted fields + photo_ref to the review screen.

## 2. Business logic
Per `ocr` design (capture stage). image_picker for camera/gallery; upload multipart; loading while OCR runs; on success → review screen (T-011) with fields + photo_ref; on error → retry.

## 3. What this task DOES
- Capture UI (camera/gallery), upload via tenants repo (T-014), progress + error states; navigate to review with results. Widget test (mocked).

## 5. Files & changes
### Add
- features/tenants/presentation/screens/ocr_capture_screen.dart; ARB; test
### Update
- app_router.dart `/tenants/add/ocr`

## 6. Database changes
None.
## 7. API changes
Consumes POST /tenants/ocr.

## 8. UI changes
- **Design source:** screen `ocr` (capture stage) — `docs/design/khatir-ui/proto/screens-landlord2.js` → `reg('ocr')`
- Surface: mobile · **Lane:** 🟢 mobile
- Route: `/tenants/add/ocr`
- Translate capture UI; values from packages/design-tokens
- States: data (capture), loading (uploading/OCR), error (retry)
- Navigation: success → OCR review (T-011)
- i18n keys: `ocr_capture_title`, `ocr_take_photo`, `ocr_from_gallery`, `ocr_processing`, `ocr_error` (bn + en)

## 9. External services
OCR (via backend).
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [ ] camera/gallery capture (image_picker)
- [ ] upload to /tenants/ocr (multipart)
- [ ] progress + error/retry states
- [ ] navigate to review with fields + photo_ref
- [ ] route /tenants/add/ocr
- [ ] ARB bn + en; widget test (mocked)
- [ ] analyze + test pass

## 12. Test plan
### Automated
- ocr_capture_test → capture → upload called → navigates to review with fields
### Manual QA
1. Snap NID → processing → review opens with fields.

## 13. Acceptance criteria
- [ ] Capture + upload + OCR + navigate works; all states.
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Image not stored locally beyond upload; tokens used
### Deviations from spec
### Files touched (actual)

## 15. Notes for the implementing agent
- Request camera permission gracefully; gallery fallback. Don't persist the raw image on device after upload.
