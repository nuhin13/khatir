---
id: T-011
epic: EPIC-14
title: Admin AI providers page (Next.js)
layer: admin
size: M
status: done
preferred_agent: claude-code
depends_on: [T-009, EPIC-11.T-008]
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

# T-011 · Admin AI providers page (Next.js)

## 1. Feature goal
4-category-tab UI for configuring AI providers (chat/voice/ocr/lease) — select vendor, enter model + API key + endpoint, set primary/fallback, test connection.

## 2. Business logic
Per admin spec. Tabs: OCR, Voice, Chat, Lease. Each tab: current primary + fallback providers; edit form; "Test connection" button; DPA warning if applicable. Super+ops.

## 3. What this task DOES
- /ai-providers page; 4 tabs; provider forms; test-connection; DPA warning. Tests.

## 5. Files & changes
### Add
- app/(dashboard)/ai-providers/page.tsx; test
### Update
- sidebar "AI providers" → /ai-providers

## 6–10.
No DB; admin 🟣; no external; no flags.

## 8. UI changes
- **Design source:** `04_Admin_Portal_Khatir.md` §AI Providers + `ui/KhatirAdmin.jsx`
- Surface: admin · **Lane:** 🟣 admin
- Route: `/(dashboard)/ai-providers`
- 4 category tabs + provider forms + test-connection + DPA warning

## 11. Implementation checklist
> Live log — check off as you go, append short commit hash. See `_handoff_protocol.md` §3b.
- [x] 4 tabs (OCR/Voice/Chat/Lease)
- [x] provider form (vendor, model, key, endpoint, primary/fallback)
- [x] "Test connection" button → shows result
- [x] DPA warning on OCR tab if non-BD provider
- [x] super+ops gate
- [x] TanStack Query; states
- [x] test: renders; test-connection fires
- [x] tsc pass

## 12. Test plan
### Automated
- ai_providers_page renders tabs; test-connection fires
## 13. Acceptance criteria
- [x] AI providers page; 4 tabs; test-connection; DPA warning; tests pass.
## 14. Self-review
- [x] DPA warning visible; API key masked in display
### Deviations from spec
- The list endpoint returns providers across all categories; the 4 tabs filter
  client-side by `category`. Vendor is a free-text/`datalist` field (the model
  stores `provider_key` as a plain CharField with no fixed choices) seeded with
  the spec §4.6.1 suggested vendors per category.
- Cost-per-unit and usage tracking (§4.6.2 cost column / §4.6.3) live on the
  separate Usage panel (T-012), not this editor page.
### Files touched (actual)
- apps/admin/src/lib/api/ai-providers.ts (new)
- apps/admin/src/components/admin/ai_providers_panel.tsx (new)
- apps/admin/src/app/(dashboard)/ai-providers/page.tsx (server guard + panel)
- apps/admin/src/app/(dashboard)/_nav.ts (AI providers → live, ops-gated)
- apps/admin/src/test/ai-providers.test.tsx (new)
- apps/admin/src/test/sidebar.test.tsx (live-pages set)
## 15. Notes
- API key shown as "••••••••••" after save — never shown in plaintext again in the UI.
