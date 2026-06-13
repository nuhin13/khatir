---
id: T-006
epic: EPIC-18
title: Flutter lease document screen
layer: mobile
size: M
status: done
preferred_agent: claude-code
depends_on: [EPIC-06.T-007, T-004]
blocks: [T-007, T-008]
external_services: []
feature_flags: [ai_lease_enabled]
started_at: 2026-06-13
completed_at: 2026-06-13
executed_by: claude-sonnet-4-6
reviewed_at:
reviewed_by:
review_outcome:
---

# T-006 · Flutter lease document screen

## 1. Feature goal
The `lease` screen: "Smart lease — DNCC-compliant contract" entry, generate via AI, then preview the draft.

## 2. Business logic
Per `lease` design (emojiHero 📜 "Smart lease", "DNCC-সম্মত চুক্তি"). From a lease → "Generate" → loading (AI) → draft clauses shown → edit (T-007) → PDF (T-008). Tier-gated → upgrade prompt. Flag-off → unavailable. Disclaimer banner.

## 3. What this task DOES
- lease_document_screen matching `lease`; generate action; draft display; disclaimer; tier/flag handling. Widget test.

## 5. Files & changes
### Add
- features/leasedocs/presentation/screens/lease_document_screen.dart; ARB; test
### Update
- router /lease/:id/document; lease detail "Generate smart lease" CTA

## 6–10.
No DB; consumes lease-document endpoints; mobile 🟢; AI via backend; flag ai_lease_enabled.

## 8. UI changes
- **Design source:** screen `lease` — Claude Design `khatir/Khatir Mobile Prototype.html` (in-repo: `docs/design/khatir-ui/proto/screens-landlord2.js` → `reg('lease')`)
- Surface: mobile · **Lane:** 🟢 mobile
- Route: `/lease/:id/document`
- Translate generate CTA + draft view + disclaimer; values from packages/design-tokens
- States: data (intro) / generating / draft / tier-gated / flag-off / error
- i18n keys: `lease_doc_title`, `lease_generate`, `lease_disclaimer`, `lease_draft` (bn + en)

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [ ] lease_document_screen matches design (📜 Smart lease)
- [ ] generate action → AI draft
- [ ] draft clause display
- [ ] disclaimer banner ("not legal advice")
- [ ] tier-gated → upgrade; flag-off → unavailable
- [ ] ARB bn + en; widget test
- [ ] analyze + test pass

## 12. Test plan
### Automated
- lease_document_test → generate fires; draft renders; disclaimer present
### Manual QA
1. From a lease → generate → draft appears with disclaimer.

## 13. Acceptance criteria
- [ ] Lease screen matches design; generate works; disclaimer shown; tier/flag handled.
- [ ] **Screen `lease` built** (ledger row).
- [ ] Test + analyze pass.

## 14. Self-review
- [ ] Disclaimer always visible; tokens; matches design
### Deviations from spec
### Files touched (actual)
## 15. Notes
- Disclaimer is non-dismissible on the draft + PDF — legal safety.
