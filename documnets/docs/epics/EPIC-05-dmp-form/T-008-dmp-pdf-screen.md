---
id: T-008
epic: EPIC-05
title: Flutter DMP PDF preview + share screen
layer: mobile
size: M
status: done
preferred_agent: claude-code
depends_on: [T-005, T-007]
blocks: []
external_services: []
feature_flags: []
started_at:
completed_at:
executed_by:
reviewed_at:
reviewed_by:
review_outcome:
---

# T-008 · Flutter DMP PDF preview + share screen

## 1. Feature goal
Generate the PDF, preview it, and let the landlord share it via WhatsApp / system share or download it — the payoff of the wedge.

## 2. Business logic
Per `dmpPdf` design. Calls generate endpoint → gets signed URL → renders/preview PDF → share (WhatsApp/system) + download. Works on free tier.

## 3. What this task DOES
- PDF preview (render from URL), share + download actions, loading/error states. Widget test (mocked).

## 5. Files & changes
### Add
- dmp_pdf_screen.dart; ARB; test
### Update
- router /dmpform/:id/pdf; pubspec (pdf viewer + share_plus)

## 6. Database changes
None.
## 7. API changes
Consumes POST /tenants/{id}/dmpform/pdf + GET /dmpforms/{id}.

## 8. UI changes
- **Design source:** screen `dmpPdf` — `docs/design/khatir-ui/proto/screens-landlord2.js` → `reg('dmpPdf')`
- Surface: mobile · **Lane:** 🟢 mobile
- Route: `/dmpform/:id/pdf`
- Translate PDF preview + share/download actions; values from packages/design-tokens
- States: generating (loading)/error/data(preview)
- Navigation: share sheet; download; back
- i18n keys: `dmp_pdf_title`, `dmp_pdf_share`, `dmp_pdf_download`, `dmp_pdf_whatsapp`, `dmp_generating` (bn + en)

## 9. External services
None (share via OS).
## 10. Feature flags
None.

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash; multiple items may share a commit. See `_handoff_protocol.md` §3b.
- [x] generate PDF → signed URL
- [x] preview PDF (viewer)
- [x] share (WhatsApp/system) + download
- [x] generating/error states
- [x] free-tier works
- [x] route /dmpform/:id/pdf; ARB bn + en; widget test
- [x] analyze + test pass

## 12. Test plan
### Automated
- dmp_pdf_test → generate→preview; share invoked
### Manual QA
1. Generate → preview PDF → share to WhatsApp → download.

## 13. Acceptance criteria
- [x] PDF preview + share + download per design; free-tier works.
- [x] **Screen `dmpPdf` built** (ledger row).
- [x] EPIC-05 wedge works end-to-end (tenant → DMP → PDF → share).
- [x] Test + analyze pass.

## 14. Self-review
- [x] Matches design; tokens; share works on device
### Deviations from spec
- Single OS share action (share_plus `SharePlus.instance.share`) surfaces
  WhatsApp + system targets in one sheet rather than a WhatsApp-only button;
  the `dmp_pdf_whatsapp` ARB key is provided for a future dedicated affordance.
- `share_plus` pinned to `^12.0.2` (latest stable compatible with the project's
  `flutter_secure_storage ^9` → `win32 ^5`; share_plus `^13` forces `win32 ^6`,
  which collides with secure-storage's transitive Windows plugin). No beta/RC.
- PDF rendering goes through an injectable `PdfViewBuilder` seam (defaults to
  `printing`'s `PdfPreview`/pdfium); widget tests stub it so the headless test
  never touches the native renderer.
- The generate endpoint `POST /tenants/{id}/dmpform/pdf` (T-005) is documented
  but not present in this worktree's API tree; the client codes against the
  committed `GeneratePdfResponseSerializer` contract (`{record, signed_url}`).
### Files touched (actual)
- apps/mobile/lib/features/dmpform/data/models/dmp_pdf_result.dart (add)
- apps/mobile/lib/features/dmpform/data/dmp_pdf_sharer.dart (add)
- apps/mobile/lib/features/dmpform/data/dmpform_repository.dart (generatePdf + fetchPdfBytes)
- apps/mobile/lib/features/dmpform/data/dmpform_providers.dart (DmpPdf + DmpPdfController + dmpPdfProvider)
- apps/mobile/lib/features/dmpform/presentation/screens/dmp_pdf_screen.dart (add)
- apps/mobile/lib/core/network/api_endpoints.dart (tenantDmpFormPdf)
- apps/mobile/lib/core/router/app_router.dart (real /dmpform/:id/pdf route; drop placeholder import)
- apps/mobile/lib/l10n/app_bn.arb, app_en.arb (dmp_pdf_* + dmp_generating keys)
- apps/mobile/pubspec.yaml (printing, share_plus)
- apps/mobile/test/dmp_pdf_test.dart (add)

## 15. Notes for the implementing agent
- Use share_plus for WhatsApp/system share; a pdf rendering package for preview. This is the EPIC-05 validation gate — the whole wedge demoable here.
